import Toybox.Lang;
import Toybox.WatchUi;

module SettingsMenu {

    function build() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.MenuTitleSettings });

        var typeLabel = (Settings.getTargetType() == Settings.TARGET_TIME) ? stringResource(Rez.Strings.LabelTime) : stringResource(Rez.Strings.LabelDistance);
        menu.addItem(new WatchUi.MenuItem(stringResource(Rez.Strings.MenuItemTargetType), typeLabel, :targetType, {}));

        menu.addItem(new WatchUi.MenuItem(
            stringResource(Rez.Strings.MenuItemTargetTime),
            formatMinutesLabel(Settings.getTargetTime() / 60),
            :targetTime,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            stringResource(Rez.Strings.MenuItemTargetDistance),
            formatKmLabel(Settings.getTargetDistance() / 100),
            :targetDistance,
            {}
        ));

        menu.addItem(new WatchUi.MenuItem(
            stringResource(Rez.Strings.MenuItemInterval),
            formatMinutesLabel(Settings.getIntervalDuration() / 60),
            :intervalDuration,
            {}
        ));

        menu.addItem(new WatchUi.ToggleMenuItem(
            stringResource(Rez.Strings.MenuItemVibration), null, :vibration, Settings.isVibrationEnabled(), {}
        ));
        menu.addItem(new WatchUi.ToggleMenuItem(
            stringResource(Rez.Strings.MenuItemSound), null, :sound, Settings.isSoundEnabled(), {}
        ));

        return menu;
    }

    function formatMinutesLabel(minutes as Number) as String {
        return minutes.format("%d") + " " + stringResource(Rez.Strings.LabelMin);
    }

    function formatKmLabel(hundredsOfMeters as Number) as String {
        var km = hundredsOfMeters / 10.0;
        return km.format("%.1f") + " " + stringResource(Rez.Strings.LabelKm);
    }

    function stringResource(resourceId) as String {
        return WatchUi.loadResource(resourceId) as String;
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
            item.setSubLabel((newType == Settings.TARGET_TIME) ? WatchUi.loadResource(Rez.Strings.LabelTime) as String : WatchUi.loadResource(Rez.Strings.LabelDistance) as String);
        } else if (id == :targetTime) {
            _editingItem = item;
            var picker = new NumberPickerView(
                WatchUi.loadResource(Rez.Strings.MenuItemTargetTime) as String,
                Settings.getTargetTime() / 60,
                5, 120, 5,
                WatchUi.loadResource(Rez.Strings.LabelMin) as String,
                method(:formatMinutes),
                method(:saveTargetTime)
            );
            WatchUi.pushView(picker, new NumberPickerDelegate(picker), WatchUi.SLIDE_LEFT);
        } else if (id == :targetDistance) {
            _editingItem = item;
            var picker = new NumberPickerView(
                WatchUi.loadResource(Rez.Strings.MenuItemTargetDistance) as String,
                Settings.getTargetDistance() / 100,
                5, 200, 5,
                WatchUi.loadResource(Rez.Strings.LabelKm) as String,
                method(:formatKm),
                method(:saveTargetDistance)
            );
            WatchUi.pushView(picker, new NumberPickerDelegate(picker), WatchUi.SLIDE_LEFT);
        } else if (id == :intervalDuration) {
            _editingItem = item;
            var picker = new NumberPickerView(
                WatchUi.loadResource(Rez.Strings.MenuItemInterval) as String,
                Settings.getIntervalDuration() / 60,
                1, 10, 1,
                WatchUi.loadResource(Rez.Strings.LabelMin) as String,
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
