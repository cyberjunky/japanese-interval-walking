import Toybox.Lang;
import Toybox.WatchUi;

class MainMenuView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => Rez.Strings.MenuTitleMain });
        addItem(new WatchUi.MenuItem(
            Rez.Strings.MenuItemStart, null, :start, {}
        ));
        addItem(new WatchUi.MenuItem(
            Rez.Strings.MenuItemSettings, null, :settings, {}
        ));
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :start) {
            var view = new WorkoutView();
            WatchUi.pushView(view, new WorkoutDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :settings) {
            var menu = SettingsMenu.build();
            WatchUi.pushView(menu, new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);
        }
    }
}
