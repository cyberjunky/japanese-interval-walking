import Toybox.Application;
import Toybox.Lang;

module Settings {

    enum {
        TARGET_TIME = 0,
        TARGET_DISTANCE = 1
    }

    const KEY_INTERVAL_DURATION = "intervalDuration";
    const KEY_TARGET_TYPE = "targetType";
    const KEY_TARGET_TIME = "targetTime";
    const KEY_TARGET_DISTANCE = "targetDistance";
    const KEY_VIBRATION = "vibration";
    const KEY_SOUND = "sound";

    const DEFAULT_INTERVAL_DURATION = 180;
    const DEFAULT_TARGET_TIME = 1800;
    const DEFAULT_TARGET_DISTANCE = 3000;

    function getIntervalDuration() as Number {
        var v = Application.Storage.getValue(KEY_INTERVAL_DURATION);
        return (v == null) ? DEFAULT_INTERVAL_DURATION : v as Number;
    }

    function setIntervalDuration(seconds as Number) as Void {
        Application.Storage.setValue(KEY_INTERVAL_DURATION, seconds);
    }

    function getTargetType() as Number {
        var v = Application.Storage.getValue(KEY_TARGET_TYPE);
        return (v == null) ? TARGET_TIME : v as Number;
    }

    function setTargetType(type as Number) as Void {
        Application.Storage.setValue(KEY_TARGET_TYPE, type);
    }

    function getTargetTime() as Number {
        var v = Application.Storage.getValue(KEY_TARGET_TIME);
        return (v == null) ? DEFAULT_TARGET_TIME : v as Number;
    }

    function setTargetTime(seconds as Number) as Void {
        Application.Storage.setValue(KEY_TARGET_TIME, seconds);
    }

    function getTargetDistance() as Number {
        var v = Application.Storage.getValue(KEY_TARGET_DISTANCE);
        return (v == null) ? DEFAULT_TARGET_DISTANCE : v as Number;
    }

    function setTargetDistance(meters as Number) as Void {
        Application.Storage.setValue(KEY_TARGET_DISTANCE, meters);
    }

    function isVibrationEnabled() as Boolean {
        var v = Application.Storage.getValue(KEY_VIBRATION);
        return (v == null) ? true : v as Boolean;
    }

    function setVibrationEnabled(enabled as Boolean) as Void {
        Application.Storage.setValue(KEY_VIBRATION, enabled);
    }

    function isSoundEnabled() as Boolean {
        var v = Application.Storage.getValue(KEY_SOUND);
        return (v == null) ? true : v as Boolean;
    }

    function setSoundEnabled(enabled as Boolean) as Void {
        Application.Storage.setValue(KEY_SOUND, enabled);
    }
}
