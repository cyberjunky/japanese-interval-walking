import Toybox.Lang;
import Toybox.WatchUi;

module SettingsMenu {

    function build() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.MenuTitleSettings });

        var typeLabel = (Settings.getTargetType() == Settings.TARGET_TIME) ? "Time" : "Distance";
        menu.addItem(new WatchUi.MenuItem("Target", typeLabel, :targetType, {}));

        menu.addItem(new WatchUi.MenuItem(
            "Target time",
            formatMinutesLabel(Settings.getTargetTime() / 60),
            :targetTime,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "Target dist",
            formatKmLabel(Settings.getTargetDistance() / 100),
            :targetDistance,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            "Interval",
            formatMinutesLabel(Settings.getIntervalDuration() / 60),
            :intervalDuration,
            {}
        ));

        menu.addItem(new WatchUi.ToggleMenuItem(
            "Vibration", null, :vibration, Settings.isVibrationEnabled(), {}
        ));
        menu.addItem(new WatchUi.ToggleMenuItem(
            "Sound", null, :sound, Settings.isSoundEnabled(), {}
        ));

        return menu;
    }

    function formatMinutesLabel(minutes as Number) as String {
        return minutes.format("%d") + " min";
    }

    function formatKmLabel(hundredsOfMeters as Number) as String {
        var km = hundredsOfMeters / 10.0;
        return km.format("%.1f") + " km";
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _editingItem as WatchUi.MenuItem?;

    function initialize() {
        Menu2InputDelegate.initialize();
        _editingItem = null;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :targetType) {
            var newType = (Settings.getTargetType() == Settings.TARGET_TIME)
                ? Settings.TARGET_DISTANCE : Settings.TARGET_TIME;
            Settings.setTargetType(newType);
            item.setSubLabel((newType == Settings.TARGET_TIME) ? "Time" : "Distance");
        } else if (id == :targetTime) {
            _editingItem = item;
            var picker = new NumberPickerView(
                "Target time",
                Settings.getTargetTime() / 60,
                5, 120, 5,
                "min",
                method(:formatMinutes),
                method(:saveTargetTime)
            );
            WatchUi.pushView(picker, new NumberPickerDelegate(picker), WatchUi.SLIDE_LEFT);
        } else if (id == :targetDistance) {
            _editingItem = item;
            var picker = new NumberPickerView(
                "Target dist",
                Settings.getTargetDistance() / 100,
                5, 200, 5,
                "km",
                method(:formatKm),
                method(:saveTargetDistance)
            );
            WatchUi.pushView(picker, new NumberPickerDelegate(picker), WatchUi.SLIDE_LEFT);
        } else if (id == :intervalDuration) {
            _editingItem = item;
            var picker = new NumberPickerView(
                "Interval",
                Settings.getIntervalDuration() / 60,
                1, 10, 1,
                "min",
                method(:formatMinutes),
                method(:saveIntervalDuration)
            );
            WatchUi.pushView(picker, new NumberPickerDelegate(picker), WatchUi.SLIDE_LEFT);
        } else if (id == :vibration) {
            Settings.setVibrationEnabled((item as WatchUi.ToggleMenuItem).isEnabled());
        } else if (id == :sound) {
            Settings.setSoundEnabled((item as WatchUi.ToggleMenuItem).isEnabled());
        }
    }

    function formatMinutes(value as Number) as String {
        return value.format("%d") + " min";
    }

    function formatKm(hundredsOfMeters as Number) as String {
        var km = hundredsOfMeters / 10.0;
        return km.format("%.1f") + " km";
    }

    function saveTargetTime(value as Number) as Void {
        Settings.setTargetTime(value * 60);
        if (_editingItem != null) {
            (_editingItem as WatchUi.MenuItem).setSubLabel(formatMinutes(value));
        }
    }

    function saveTargetDistance(value as Number) as Void {
        Settings.setTargetDistance(value * 100);
        if (_editingItem != null) {
            (_editingItem as WatchUi.MenuItem).setSubLabel(formatKm(value));
        }
    }

    function saveIntervalDuration(value as Number) as Void {
        Settings.setIntervalDuration(value * 60);
        if (_editingItem != null) {
            (_editingItem as WatchUi.MenuItem).setSubLabel(formatMinutes(value));
        }
    }
}
