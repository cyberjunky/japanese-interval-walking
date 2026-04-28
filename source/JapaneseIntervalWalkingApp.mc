import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class JapaneseIntervalWalkingApp extends Application.AppBase {

    public var activeController as IntervalController?;

    function initialize() {
        AppBase.initialize();
        activeController = null;
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
        if (activeController != null) {
            (activeController as IntervalController).stop(false);
            activeController = null;
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new MainMenuView();
        return [ view, new MainMenuDelegate() ];
    }
}

function getApp() as JapaneseIntervalWalkingApp {
    return Application.getApp() as JapaneseIntervalWalkingApp;
}
