import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SummaryView extends WatchUi.View {

    private var _controller as IntervalController;
    private var _saved as Boolean;

    function initialize(controller as IntervalController, saved as Boolean) {
        View.initialize();
        _controller = controller;
        _saved = saved;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(_saved ? Graphics.COLOR_GREEN : Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        var header = _saved ? "Workout Saved" : "Workout";
        dc.drawText(w / 2, (h * 0.07).toNumber(), Graphics.FONT_SMALL, header, Graphics.TEXT_JUSTIFY_CENTER);

        var totalStr = formatMMSS(_controller.totalElapsed);
        var distStr = (_controller.finalDistance / 1000.0).format("%.2f") + " km";
        var lapStr = _controller.lapCount.format("%d");
        var hrStr = (_controller.finalAvgHr != null)
            ? (_controller.finalAvgHr as Number).format("%d") + " bpm"
            : "-- bpm";
        var calStr = (_controller.finalCalories != null)
            ? (_controller.finalCalories as Number).format("%d") + " kcal"
            : "-- kcal";

        var startY = (h * 0.22).toFloat();
        var dy = (h * 0.13).toFloat();

        drawRow(dc, w, (startY + 0 * dy).toNumber(), "Time", totalStr);
        drawRow(dc, w, (startY + 1 * dy).toNumber(), "Distance", distStr);
        drawRow(dc, w, (startY + 2 * dy).toNumber(), "Laps", lapStr);
        drawRow(dc, w, (startY + 3 * dy).toNumber(), "Avg HR", hrStr);
        drawRow(dc, w, (startY + 4 * dy).toNumber(), "Calories", calStr);
    }

    function drawRow(dc as Dc, w as Number, y as Number, label as String, value as String) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.48).toNumber(), y, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.52).toNumber(), y, Graphics.FONT_XTINY, value, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function formatMMSS(seconds as Number) as String {
        var m = seconds / 60;
        var s = seconds % 60;
        return m.format("%d") + ":" + s.format("%02d");
    }
}

class SummaryDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
