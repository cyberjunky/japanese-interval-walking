import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class NumberPickerView extends WatchUi.View {

    public var value as Number;
    public var minValue as Number;
    public var maxValue as Number;
    public var step as Number;
    public var title as String;
    public var unit as String;

    private var _formatter as Method;
    private var _saver as Method;

    function initialize(
        title as String,
        initial as Number,
        minV as Number,
        maxV as Number,
        step as Number,
        unit as String,
        formatter as Method,
        saver as Method
    ) {
        View.initialize();
        self.title = title;
        self.value = initial;
        self.minValue = minV;
        self.maxValue = maxV;
        self.step = step;
        self.unit = unit;
        self._formatter = formatter;
        self._saver = saver;
    }

    function increment() as Void {
        value += step;
        if (value > maxValue) { value = maxValue; }
        WatchUi.requestUpdate();
    }

    function decrement() as Void {
        value -= step;
        if (value < minValue) { value = minValue; }
        WatchUi.requestUpdate();
    }

    function save() as Void {
        _saver.invoke(value);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.10).toNumber(), Graphics.FONT_TINY, title, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var text = _formatter.invoke(value) as String;
        dc.drawText(w / 2, (h * 0.36).toNumber(), Graphics.FONT_NUMBER_MEDIUM, text, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.50).toNumber(), (h * 0.65).toNumber(), Graphics.FONT_TINY, WatchUi.loadResource(Rez.Strings.LabelUpDown) as String, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.82).toNumber(), Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.LabelSelectSave) as String, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class NumberPickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NumberPickerView;

    function initialize(view as NumberPickerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Boolean {
        _view.increment();
        return true;
    }

    function onNextPage() as Boolean {
        _view.decrement();
        return true;
    }

    function onSelect() as Boolean {
        _view.save();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
