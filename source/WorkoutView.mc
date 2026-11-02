import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// Modern, minimal workout screen with a Japanese-inspired palette (kurenai red
// for fast, ai indigo for slow, yamabuki amber for warmup, matcha for cooldown).
// Round screens get a thin ensō-style section ring; rectangular screens get a
// segmented progress bar instead. All glyphs are drawn with primitives or vector
// fonts, so the layout scales cleanly to every screen size.
class WorkoutView extends WatchUi.View {

    public var controller as IntervalController;

    private const COLOR_TEXT = 0xFFFFFF;
    private const COLOR_MUTED = 0x8A8F98;
    private const COLOR_TRACK = 0x2A2E35;
    private const COLOR_FAST = 0xE60033;
    private const COLOR_SLOW = 0x2F6FED;
    private const COLOR_WARMUP = 0xF2B01E;
    private const COLOR_COOLDOWN = 0x58B368;

    private var _w as Number = 0;
    private var _h as Number = 0;
    private var _isRect as Boolean = false;
    private var _fontTitle;
    private var _fontCountdown;
    private var _fontValue;
    private var _fontLabel;

    function initialize() {
        View.initialize();
        controller = new IntervalController();
        controller.setCallbacks(method(:onTickFromController), method(:onFinishFromController));
        getApp().activeController = controller;
    }

    function onShow() as Void {
        if (!controller.running && !controller.finished && controller.totalElapsed == 0) {
            controller.start();
        }
        WatchUi.requestUpdate();
    }

    // Vector fonts are unavailable on many MIP devices (e.g. FR255/955). Guard the
    // call and fall back to built-in fonts, which always exist.
    function onLayout(dc as Dc) as Void {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _isRect = (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_RECTANGLE);

        _fontTitle = null;
        _fontCountdown = null;
        _fontValue = null;
        _fontLabel = null;
        if (Graphics has :getVectorFont) {
            var faces = ["Roboto Condensed", "Roboto", "Arial"];
            _fontTitle = Graphics.getVectorFont({ :face => faces, :size => (_h * 0.060).toNumber() });
            _fontCountdown = Graphics.getVectorFont({ :face => faces, :size => (_h * 0.16).toNumber() });
            _fontValue = Graphics.getVectorFont({ :face => faces, :size => (_h * 0.050).toNumber() });
            _fontLabel = Graphics.getVectorFont({ :face => faces, :size => (_h * 0.036).toNumber() });
        }
        if (_fontTitle == null) { _fontTitle = Graphics.FONT_SMALL; }
        if (_fontCountdown == null) { _fontCountdown = Graphics.FONT_NUMBER_HOT; }
        if (_fontValue == null) { _fontValue = Graphics.FONT_SMALL; }
        if (_fontLabel == null) { _fontLabel = Graphics.FONT_XTINY; }
    }

    function onTickFromController() as Void {
        WatchUi.requestUpdate();
    }

    function onFinishFromController() as Void {
        controller.stop(true);
        var summary = new SummaryView(controller, true);
        WatchUi.switchToView(summary, new SummaryDelegate(), WatchUi.SLIDE_LEFT);
    }

    function phaseColor(phase as Number) as Number {
        if (phase == Phase.PHASE_FAST) { return COLOR_FAST; }
        if (phase == Phase.PHASE_SLOW) { return COLOR_SLOW; }
        if (phase == Phase.PHASE_WARMUP) { return COLOR_WARMUP; }
        return COLOR_COOLDOWN;
    }

    function onUpdate(dc as Dc) as Void {
        var w = _w;
        var h = _h;
        var ph = controller.phase;
        var color = phaseColor(ph);
        var isWarmup = (ph == Phase.PHASE_WARMUP);
        var isCooldown = (ph == Phase.PHASE_COOLDOWN);
        var paused = !controller.running && !controller.finished;

        dc.setColor(COLOR_TEXT, Graphics.COLOR_BLACK);
        dc.clear();

        // Vertical stack measured with real font heights: title, countdown,
        // metrics (near the vertical centre, where round screens are widest),
        // phase emblem, then the footer. Adapts to every screen size.
        var labelH = Graphics.getFontHeight(_fontLabel);
        var countH = Graphics.getFontHeight(_fontCountdown);
        var valueH = Graphics.getFontHeight(_fontValue);

        // Section progress: ring on round screens, segmented bar on rectangular ones
        var showBar = _isRect && !isWarmup && !isCooldown;
        if (!isWarmup && !isCooldown) {
            if (_isRect) {
                drawSectionBar(dc, controller.lapCount, controller.totalSections());
            } else {
                drawSectionRing(dc, controller.lapCount, controller.totalSections());
            }
        }

        // Phase title
        var phaseText;
        if (isWarmup) {
            phaseText = stringResource(Rez.Strings.LabelPhaseWarmup);
        } else if (isCooldown) {
            phaseText = stringResource(Rez.Strings.LabelPhaseCooldown);
        } else {
            phaseText = (ph == Phase.PHASE_FAST) ? stringResource(Rez.Strings.LabelPhaseFast) : stringResource(Rez.Strings.LabelPhaseSlow);
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.105).toNumber(), _fontTitle, phaseText, Graphics.TEXT_JUSTIFY_CENTER);

        // Countdown
        var countCenterY = (h * 0.35).toNumber();
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, countCenterY - countH / 2, _fontCountdown, formatMMSS(controller.phaseRemaining()), Graphics.TEXT_JUSTIFY_CENTER);

        // Metrics row: time, distance, heart rate. Placed near the vertical centre
        // where the round bezel shadow is thinnest; calories are on the summary.
        var info = Activity.getActivityInfo();
        var distM = (info != null && info.elapsedDistance != null) ? info.elapsedDistance as Float : 0.0;
        var distStr;
        var distLabel;
        if (Settings.isDistanceStatute()) {
            distStr = (distM / Settings.METERS_PER_MILE).format("%.2f");
            distLabel = stringResource(Rez.Strings.LabelMiShort);
        } else {
            distStr = (distM / 1000.0).format("%.2f");
            distLabel = stringResource(Rez.Strings.LabelKmShort);
        }
        var hrNow = (info != null && info.currentHeartRate != null) ? info.currentHeartRate as Number : null;
        var hrStr = (hrNow != null) ? (hrNow as Number).format("%d") : "--";

        var countBottom = countCenterY + countH / 2;
        var metricLabelY = (h * 0.53).toNumber();
        var minLabelY = countBottom + (h * 0.02).toNumber();
        if (metricLabelY < minLabelY) { metricLabelY = minLabelY; }
        var metricValueY = metricLabelY + labelH + 1;
        drawMetric(dc, (w * 0.22).toNumber(), metricLabelY, metricValueY, stringResource(Rez.Strings.LabelTotal), formatMMSS(controller.totalElapsed));
        drawMetric(dc, (w * 0.50).toNumber(), metricLabelY, metricValueY, distLabel, distStr);
        drawMetric(dc, (w * 0.78).toNumber(), metricLabelY, metricValueY, stringResource(Rez.Strings.LabelHR), hrStr);

        // Phase emblem: bold vector-drawn mark (chevrons, sun, ensō, crescent)
        var emblemS = (h * 0.085).toNumber();
        var emblemY = metricValueY + valueH + (h * 0.03).toNumber() + emblemS / 2;
        var emblemMaxY = (h * 0.85).toNumber() - emblemS / 2;
        if (emblemY > emblemMaxY) { emblemY = emblemMaxY; }
        drawEmblem(dc, w / 2, emblemY, emblemS, ph, paused ? COLOR_MUTED : color, paused);

        // Section counter (skipped when the segmented bar already shows progress)
        if (!showBar) {
            var footText;
            if (paused) {
                footText = stringResource(Rez.Strings.LabelPaused);
            } else if (isWarmup) {
                footText = stringResource(Rez.Strings.LabelWarmup);
            } else if (isCooldown) {
                footText = stringResource(Rez.Strings.LabelCooldown);
            } else {
                var totalSecs = controller.totalSections();
                footText = (totalSecs > 0)
                    ? controller.lapCount.format("%d") + " / " + totalSecs.format("%d")
                    : controller.lapCount.format("%d");
            }
            dc.setColor(paused ? COLOR_WARMUP : COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 0.895).toNumber(), _fontLabel, footText, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawMetric(dc as Dc, centerX as Number, labelY as Number, valueY as Number, label as String, value as String) as Void {
        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, labelY, _fontLabel, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, valueY, _fontValue, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Minimal phase marks drawn with primitives so they scale to any screen:
    // fast = twin chevrons (speed), other phases = ensō-inspired open arc.
    // Bold vector symbol per phase, drawn with primitives so it scales to any
    // screen: fast = twin chevrons, slow = ensō ring, warmup = rising sun,
    // cooldown = crescent moon, paused = twin bars.
    function drawEmblem(dc as Dc, cx as Number, cy as Number, s as Number, phase as Number, color as Number, paused as Boolean) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (paused) {
            var barW = s / 4;
            if (barW < 3) { barW = 3; }
            var gap = (s * 0.3).toNumber();
            dc.fillRectangle(cx - gap / 2 - barW, cy - s / 2, barW, s);
            dc.fillRectangle(cx + gap / 2, cy - s / 2, barW, s);
            return;
        }
        if (phase == Phase.PHASE_FAST) {
            drawChevrons(dc, cx, cy, s);
        } else if (phase == Phase.PHASE_SLOW) {
            drawEnso(dc, cx, cy, s);
        } else if (phase == Phase.PHASE_WARMUP) {
            drawSun(dc, cx, cy, s);
        } else {
            drawCrescent(dc, cx, cy, s);
        }
    }

    // Two solid forward chevrons: speed.
    function drawChevrons(dc as Dc, cx as Number, cy as Number, s as Number) as Void {
        var t = (s * 0.24).toNumber();
        var d = (s * 0.30).toNumber();
        for (var k = 0; k < 2; k++) {
            var x0 = cx - (s * 0.48).toNumber() + (k * s * 0.44).toNumber();
            dc.fillPolygon([
                [x0, cy - s / 2],
                [x0 + t, cy - s / 2],
                [x0 + t + d, cy],
                [x0 + t, cy + s / 2],
                [x0, cy + s / 2],
                [x0 + d, cy]
            ]);
        }
    }

    // Thick ensō ring: a 300° brush stroke with a dot marking the stroke head.
    function drawEnso(dc as Dc, cx as Number, cy as Number, s as Number) as Void {
        var pen = (s * 0.30).toNumber();
        if (pen < 4) { pen = 4; }
        var r = s / 2 - pen / 2;
        dc.setPenWidth(pen);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 120, 180);
        dc.setPenWidth(1);
        // Brush dot at the start of the stroke (lower right of the gap)
        var a = 120 * Math.PI / 180;
        dc.fillCircle((cx + r * Math.cos(a)).toNumber(), (cy - r * Math.sin(a)).toNumber(), pen / 2);
    }

    // Rising sun: filled disc with rays.
    function drawSun(dc as Dc, cx as Number, cy as Number, s as Number) as Void {
        var discR = (s * 0.26).toNumber();
        dc.fillCircle(cx, cy, discR);
        var r1 = s * 0.40;
        var r2 = s * 0.50;
        var pen = s / 10;
        if (pen < 2) { pen = 2; }
        dc.setPenWidth(pen);
        for (var i = 0; i < 8; i++) {
            var a = i * Math.PI / 4;
            var ca = Math.cos(a);
            var sa = Math.sin(a);
            dc.drawLine(
                (cx + r1 * ca).toNumber(), (cy - r1 * sa).toNumber(),
                (cx + r2 * ca).toNumber(), (cy - r2 * sa).toNumber()
            );
        }
        dc.setPenWidth(1);
    }

    // Crescent moon: coloured disc with an offset disc cut out of it.
    function drawCrescent(dc as Dc, cx as Number, cy as Number, s as Number) as Void {
        var r = (s * 0.44).toNumber();
        dc.fillCircle(cx, cy, r);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + (s * 0.20).toNumber(), cy - (s * 0.12).toNumber(), (s * 0.36).toNumber());
    }

    // Thin segmented ring around the watch edge: completed = section colour,
    // current = heavier stroke, upcoming = dark track.
    function drawSectionRing(dc as Dc, lapCurrent as Number, totalSecs as Number) as Void {
        var m = (_w < _h) ? _w : _h;
        var cx = _w / 2;
        var cy = _h / 2;
        var r = m / 2 - 7;

        dc.setPenWidth(4);
        dc.setColor(COLOR_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 0, 359);

        var displayCount = (totalSecs > 0) ? totalSecs : lapCurrent + 4;
        if (displayCount < 1) { displayCount = 1; }
        if (displayCount > 60) { displayCount = 60; }

        var gapDeg = 3;
        var sweepDeg = (360 - displayCount * gapDeg) / displayCount;
        if (sweepDeg < 4) {
            gapDeg = 1;
            sweepDeg = (360 - displayCount * gapDeg) / displayCount;
        }
        if (sweepDeg < 2) { sweepDeg = 2; }

        for (var i = 0; i < displayCount; i++) {
            var sectionNum = i + 1;
            if (sectionNum > lapCurrent) { break; }

            var segColor = ((i % 2) == 0) ? COLOR_FAST : COLOR_SLOW;
            var penW = (sectionNum == lapCurrent) ? 8 : 4;

            // Arcs start at 12 o'clock (90°) and progress clockwise
            var startDeg = ((90 - i * (sweepDeg + gapDeg)) % 360 + 360) % 360;
            var endDeg = ((startDeg - sweepDeg) % 360 + 360) % 360;

            dc.setPenWidth(penW);
            dc.setColor(segColor, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, startDeg, endDeg);
        }

        dc.setPenWidth(1);
    }

    // Segmented progress bar along the bottom edge for rectangular screens.
    function drawSectionBar(dc as Dc, lapCurrent as Number, totalSecs as Number) as Void {
        var x0 = (_w * 0.10).toNumber();
        var x1 = (_w * 0.90).toNumber();
        var y = (_h * 0.93).toNumber();
        var barH = (_h * 0.02).toNumber();
        if (barH < 5) { barH = 5; }

        var displayCount = (totalSecs > 0) ? totalSecs : lapCurrent + 4;
        if (displayCount < 1) { displayCount = 1; }
        if (displayCount > 60) { displayCount = 60; }

        var gap = 2;
        var segW = (x1 - x0 - (displayCount - 1) * gap) / displayCount;
        if (segW < 2) { segW = 2; gap = 1; }

        for (var i = 0; i < displayCount; i++) {
            var sectionNum = i + 1;
            var sx = x0 + i * (segW + gap);
            if (sectionNum <= lapCurrent) {
                dc.setColor(((i % 2) == 0) ? COLOR_FAST : COLOR_SLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(COLOR_TRACK, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillRectangle(sx, y, segW, barH);
        }
    }

    function formatMMSS(seconds as Number) as String {
        var m = seconds / 60;
        var s = seconds % 60;
        return m.format("%d") + ":" + s.format("%02d");
    }

    function stringResource(resourceId) as String {
        return WatchUi.loadResource(resourceId) as String;
    }
}
