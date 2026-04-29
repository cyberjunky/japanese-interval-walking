import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class WorkoutView extends WatchUi.View {

    public var controller as IntervalController;
    private var _phaseFont;
    private var _metricFont;

    function initialize() {
        View.initialize();
        controller = new IntervalController();
        controller.setCallbacks(method(:onTickFromController), method(:onFinishFromController));
        getApp().activeController = controller;
        _phaseFont = Graphics.getVectorFont({ :face => ["Roboto Condensed", "Roboto", "Arial"], :size => 22 });
        _metricFont = Graphics.getVectorFont({ :face => ["Roboto Condensed", "Roboto", "Arial"], :size => 16 });
    }

    function onShow() as Void {
        if (!controller.running && !controller.finished && controller.totalElapsed == 0) {
            controller.start();
        }
        WatchUi.requestUpdate();
    }

    function onTickFromController() as Void {
        WatchUi.requestUpdate();
    }

    function onFinishFromController() as Void {
        controller.stop(true);
        var summary = new SummaryView(controller, true);
        WatchUi.switchToView(summary, new SummaryDelegate(), WatchUi.SLIDE_LEFT);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var fast = (controller.phase == Phase.PHASE_FAST);
        var phaseColor = fast ? Graphics.COLOR_DK_RED : Graphics.COLOR_DK_BLUE;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();

        // Section ring drawn first so all text renders on top
        var totalSecs = controller.totalSections();
        drawSectionRing(dc, controller.lapCount, totalSecs);

        var phaseText = fast ? "Fast (Hayaku)" : "Slow (Yukkuri)";
        dc.setColor(phaseColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.135).toNumber(), pickPhaseFont(), phaseText, Graphics.TEXT_JUSTIFY_CENTER);

        var rem = controller.phaseRemaining();
        var remStr = formatMMSS(rem);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.20).toNumber(), Graphics.FONT_NUMBER_HOT, remStr, Graphics.TEXT_JUSTIFY_CENTER);

        var info = Activity.getActivityInfo();
        var totalStr = formatMMSS(controller.totalElapsed);
        var distM = (info != null && info.elapsedDistance != null) ? info.elapsedDistance as Float : 0.0;
        var distStr = (distM / 1000.0).format("%.2f");
        var hrNow = (info != null && info.currentHeartRate != null) ? info.currentHeartRate as Number : null;
        var hrStr = (hrNow != null) ? (hrNow as Number).format("%d") : "--";
        var calStr = (info != null && info.calories != null) ? (info.calories as Number).format("%d") : "--";
        var sectionStr = (totalSecs > 0)
            ? controller.lapCount.format("%d") + "/" + totalSecs.format("%d")
            : controller.lapCount.format("%d") + "/?";

        var leftColX = (w * 0.23).toNumber();
        var rightColX = (w * 0.77).toNumber();
        var row1Y = (h * 0.57).toNumber();
        var row2Y = (h * 0.74).toNumber();
        var footerY = (h * 0.87).toNumber();
        var iconCenterY = (h * 0.66).toNumber();

        drawMetric(dc, leftColX, row1Y, "TIME", totalStr);
        drawMetric(dc, rightColX, row1Y, "KM", distStr);
        drawMetric(dc, leftColX, row2Y, "HR", hrStr);
        drawMetric(dc, rightColX, row2Y, "KCAL", calStr);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, footerY - 24, Graphics.FONT_XTINY, "SECTION", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, footerY, pickMetricFont(), sectionStr, Graphics.TEXT_JUSTIFY_CENTER);

        if (!controller.running && !controller.finished) {
            drawPauseIcon(dc, w / 2, iconCenterY, phaseColor);
        } else {
            drawPhaseIcon(dc, w / 2, iconCenterY, 112, fast);
        }
    }

    function drawMetric(dc as Dc, centerX as Number, y as Number, label as String?, value as String) as Void {
        if (label != null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y - 28, Graphics.FONT_XTINY, label as String, Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, pickMetricFont(), value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function pickPhaseFont() {
        return (_phaseFont != null) ? _phaseFont : Graphics.FONT_SMALL;
    }

    function pickMetricFont() {
        return (_metricFont != null) ? _metricFont : Graphics.FONT_TINY;
    }

    function drawPauseIcon(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        var icon = WatchUi.loadResource(Rez.Drawables.PauseIcon);
        var size = 70;
        var half = size / 2;
        dc.drawScaledBitmap(cx - half, cy - half, size, size, icon);
    }

    function drawPhaseIcon(dc as Dc, cx as Number, cy as Number, size as Number, fast as Boolean) as Void {
        var iconRes = fast ? Rez.Drawables.RabbitIcon : Rez.Drawables.TurtleIcon;
        var icon = WatchUi.loadResource(iconRes);
        var half = size / 2;
        dc.drawScaledBitmap(cx - half, cy - half, size, size, icon);
    }

    // Draws arc segments around the watch edge: past=type colour, current=thicker type colour, upcoming=grey
    function drawSectionRing(dc as Dc, lapCurrent as Number, totalSecs as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var r = (w < h ? w : h) / 2 - 9;

        var displayCount = (totalSecs > 0) ? totalSecs : lapCurrent + 4;
        if (displayCount < 1) { displayCount = 1; }
        if (displayCount > 60) { displayCount = 60; }

        var gapDeg = 3;
        var sweepDeg = (360 - displayCount * gapDeg) / displayCount;
        if (sweepDeg < 4) {
            // Too tight — shrink gap
            gapDeg = 1;
            sweepDeg = (360 - displayCount * gapDeg) / displayCount;
        }
        if (sweepDeg < 2) { sweepDeg = 2; }

        // Light neutral base ring keeps the watch face clean on a white background
        dc.setPenWidth(10);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 0, 359);

        for (var i = 0; i < displayCount; i++) {
            var isFast = ((i % 2) == 0);  // section 1 (i=0) starts fast
            var sectionNum = i + 1;

            // Arcs start at 12 o'clock (90°) and progress clockwise
            var startDeg = ((90 - i * (sweepDeg + gapDeg)) % 360 + 360) % 360;
            var endDeg   = ((startDeg - sweepDeg) % 360 + 360) % 360;

            var color;
            var penW;
            if (sectionNum < lapCurrent) {
                // Completed — type colour
                color = isFast ? Graphics.COLOR_DK_RED : Graphics.COLOR_DK_BLUE;
                penW = 8;
            } else if (sectionNum == lapCurrent) {
                // Current — same type colour, just heavier so it stands out
                color = isFast ? Graphics.COLOR_DK_RED : Graphics.COLOR_DK_BLUE;
                penW = 14;
            } else {
                // Upcoming — dim neutral
                color = Graphics.COLOR_LT_GRAY;
                penW = 6;
            }

            dc.setPenWidth(penW);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, startDeg, endDeg);
        }

        dc.setPenWidth(1);
    }

    function formatMMSS(seconds as Number) as String {
        var m = seconds / 60;
        var s = seconds % 60;
        return m.format("%d") + ":" + s.format("%02d");
    }
}
