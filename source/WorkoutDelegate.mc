import Toybox.Lang;
import Toybox.WatchUi;

class WorkoutDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WorkoutView;

    function initialize(view as WorkoutView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var c = _view.controller;
        if (c.finished) { return true; }
        if (c.running) {
            c.pause();
        } else {
            c.resume();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        var c = _view.controller;
        if (c.totalElapsed > 0) {
            c.pause();
            WatchUi.pushView(
                new WatchUi.Confirmation("Save workout?"),
                new SaveConfirmationDelegate(_view),
                WatchUi.SLIDE_UP
            );
        } else {
            c.stop(false);
            getApp().activeController = null;
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }

    function onNextPage() as Boolean {
        var c = _view.controller;
        if (c.running) {
            c.skipPhase();
            WatchUi.requestUpdate();
        }
        return true;
    }
}

class SaveConfirmationDelegate extends WatchUi.ConfirmationDelegate {

    private var _view as WorkoutView;

    function initialize(view as WorkoutView) {
        ConfirmationDelegate.initialize();
        _view = view;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        var c = _view.controller;
        if (response == WatchUi.CONFIRM_YES) {
            c.stop(true);
            getApp().activeController = null;
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.switchToView(new SummaryView(c, true), new SummaryDelegate(), WatchUi.SLIDE_LEFT);
        } else {
            c.stop(false);
            getApp().activeController = null;
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}
