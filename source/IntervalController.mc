import Toybox.Lang;
import Toybox.Timer;
import Toybox.System;
import Toybox.Attention;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Position;
import Toybox.WatchUi;

module Phase {
    enum {
        PHASE_FAST = 0,
        PHASE_SLOW = 1
    }
}

class IntervalController {

    public var phase as Number;
    public var phaseElapsed as Number;
    public var totalElapsed as Number;
    public var lapCount as Number;
    public var running as Boolean;
    public var finished as Boolean;
    public var targetReached as Boolean;

    public var finalDistance as Float;
    public var finalAvgHr as Number?;
    public var finalCalories as Number?;

    private var _timer as Timer.Timer?;
    private var _session as ActivityRecording.Session?;
    private var _intervalDuration as Number;
    private var _targetType as Number;
    private var _targetTime as Number;
    private var _targetDistance as Number;
    private var _gpsEnabled as Boolean;
    private var _onTickCb as Method?;
    private var _onFinishCb as Method?;

    function initialize() {
        phase = Phase.PHASE_FAST;
        phaseElapsed = 0;
        totalElapsed = 0;
        lapCount = 1;
        running = false;
        finished = false;
        targetReached = false;
        finalDistance = 0.0;
        finalAvgHr = null;
        finalCalories = null;
        _timer = null;
        _session = null;
        _onTickCb = null;
        _onFinishCb = null;
        _intervalDuration = Settings.getIntervalDuration();
        _targetType = Settings.getTargetType();
        _targetTime = Settings.getTargetTime();
        _targetDistance = Settings.getTargetDistance();
        _gpsEnabled = false;
    }

    function setCallbacks(onTick as Method, onFinish as Method) as Void {
        _onTickCb = onTick;
        _onFinishCb = onFinish;
    }

    function start() as Void {
        if (running) { return; }
        ensureGpsTracking();
        if (_session == null && Toybox has :ActivityRecording) {
            try {
                _session = ActivityRecording.createSession({
                    :name => buildSessionName(),
                    :sport => Activity.SPORT_WALKING,
                    :subSport => Activity.SUB_SPORT_GENERIC
                });
            } catch (e) {
                _session = null;
            }
        }
        if (_session != null) {
            var s = _session as ActivityRecording.Session;
            if (!s.isRecording()) {
                s.start();
            }
        }
        running = true;
        notifyPhaseStart();
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        (_timer as Timer.Timer).start(method(:onTick), 1000, true);
    }

    function pause() as Void {
        if (!running) { return; }
        running = false;
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
        }
        if (_session != null) {
            var s = _session as ActivityRecording.Session;
            if (s.isRecording()) {
                s.stop();
            }
        }
    }

    function resume() as Void {
        if (running || finished) { return; }
        running = true;
        if (_session != null) {
            var s = _session as ActivityRecording.Session;
            if (!s.isRecording()) {
                s.start();
            }
        }
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        (_timer as Timer.Timer).start(method(:onTick), 1000, true);
    }

    function skipPhase() as Void {
        advancePhase();
    }

    function totalSections() as Number {
        if (_targetType == Settings.TARGET_TIME) {
            return _targetTime / _intervalDuration;
        }
        return -1;
    }

    function stop(save as Boolean) as Void {
        if (finished) { return; }
        snapshotFinalStats();
        disableGpsTracking();
        running = false;
        finished = true;
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
        if (_session != null) {
            var s = _session as ActivityRecording.Session;
            if (s.isRecording()) {
                s.stop();
            }
            if (save) {
                s.save();
            } else {
                s.discard();
            }
            _session = null;
        }
    }

    function onTick() as Void {
        if (!running) { return; }
        phaseElapsed += 1;
        totalElapsed += 1;

        var targetHit = false;
        if (_targetType == Settings.TARGET_TIME) {
            if (totalElapsed >= _targetTime) { targetHit = true; }
        } else {
            if (currentDistance() >= _targetDistance.toFloat()) { targetHit = true; }
        }

        if (targetHit) {
            targetReached = true;
            playFinishCue();
            if (_onFinishCb != null) {
                (_onFinishCb as Method).invoke();
            }
            return;
        }

        if (phaseElapsed >= _intervalDuration) {
            advancePhase();
        }

        if (_onTickCb != null) {
            (_onTickCb as Method).invoke();
        }
    }

    function advancePhase() as Void {
        phase = (phase == Phase.PHASE_FAST) ? Phase.PHASE_SLOW : Phase.PHASE_FAST;
        phaseElapsed = 0;
        lapCount += 1;
        if (_session != null) {
            var s = _session as ActivityRecording.Session;
            if (s.isRecording()) {
                s.addLap();
            }
        }
        notifyPhaseStart();
        if (_onTickCb != null) {
            (_onTickCb as Method).invoke();
        }
    }

    function notifyPhaseStart() as Void {
        var devSettings = System.getDeviceSettings();
        if (Settings.isVibrationEnabled() && (Toybox has :Attention) && (Attention has :vibrate) && devSettings.vibrateOn) {
            var pattern;
            if (phase == Phase.PHASE_FAST) {
                pattern = [
                    new Attention.VibeProfile(100, 400),
                    new Attention.VibeProfile(0, 150),
                    new Attention.VibeProfile(100, 400),
                    new Attention.VibeProfile(0, 150),
                    new Attention.VibeProfile(100, 400)
                ];
            } else {
                pattern = [
                    new Attention.VibeProfile(75, 700),
                    new Attention.VibeProfile(0, 200),
                    new Attention.VibeProfile(75, 700)
                ];
            }
            Attention.vibrate(pattern);
        }
        if (Settings.isSoundEnabled() && (Toybox has :Attention) && (Attention has :playTone) && devSettings.tonesOn) {
            var tone = (phase == Phase.PHASE_FAST) ? Attention.TONE_INTERVAL_ALERT : Attention.TONE_LAP;
            Attention.playTone(tone);
        }
    }

    function playFinishCue() as Void {
        var devSettings = System.getDeviceSettings();
        if (Settings.isVibrationEnabled() && (Toybox has :Attention) && (Attention has :vibrate) && devSettings.vibrateOn) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 800),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(100, 800),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(100, 800)
            ]);
        }
        if (Settings.isSoundEnabled() && (Toybox has :Attention) && (Attention has :playTone) && devSettings.tonesOn) {
            Attention.playTone(Attention.TONE_SUCCESS);
        }
    }

    function snapshotFinalStats() as Void {
        var info = Activity.getActivityInfo();
        if (info != null) {
            if (info.elapsedDistance != null) {
                finalDistance = info.elapsedDistance as Float;
            }
            if (info.averageHeartRate != null) {
                finalAvgHr = info.averageHeartRate as Number;
            }
            if (info.calories != null) {
                finalCalories = info.calories as Number;
            }
        }
    }

    function buildSessionName() as String {
        // Keep the title short and stable. Garmin Connect can derive the visible location
        // from the recorded GPS track, but Connect IQ does not provide reverse geocoding.
        return "Japanese Walk";
    }

    function ensureGpsTracking() as Void {
        if (_gpsEnabled) { return; }
        if (!(Toybox has :Position)) { return; }

        try {
            if (Position has :LOCATION_CONTINUOUS) {
                Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPositionUpdate));
                _gpsEnabled = true;
            }
        } catch (e) {
            _gpsEnabled = false;
        }
    }

    function disableGpsTracking() as Void {
        if (!_gpsEnabled) { return; }
        try {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        } catch (e) {
        }
        _gpsEnabled = false;
    }

    function onPositionUpdate(info as Position.Info) as Void {
        // The recording session persists the GPS track; this callback only keeps
        // positioning active while the workout is running.
    }

    function phaseRemaining() as Number {
        var r = _intervalDuration - phaseElapsed;
        return r < 0 ? 0 : r;
    }

    function currentDistance() as Float {
        var info = Activity.getActivityInfo();
        if (info != null && info.elapsedDistance != null) {
            return info.elapsedDistance as Float;
        }
        return 0.0;
    }

    function targetType() as Number { return _targetType; }
    function targetTime() as Number { return _targetTime; }
    function targetDistance() as Number { return _targetDistance; }
    function intervalDuration() as Number { return _intervalDuration; }
}
