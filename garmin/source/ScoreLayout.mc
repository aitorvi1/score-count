import Toybox.System;
import Toybox.Lang;

// Drawing and hit testing share these bounds. No device-specific pixel positions.
class ScoreLayout {
    static const ZONE_NONE = 0;
    static const ZONE_BLUE = 1;
    static const ZONE_RED = 2;
    static const ZONE_RESET = 3;

    var width as Lang.Number = 0;
    var height as Lang.Number = 0;
    var blue as Lang.Array<Lang.Number> = [0, 0, 0, 0];
    var red as Lang.Array<Lang.Number> = [0, 0, 0, 0];
    var reset as Lang.Array<Lang.Number> = [0, 0, 0, 0];

    function initialize() {
        var settings = System.getDeviceSettings();
        resize(settings.screenWidth, settings.screenHeight);
    }

    function resize(w as Lang.Number, h as Lang.Number) {
        width = w;
        height = h;
        blue = [(w * 0.08).toNumber(), (h * 0.18).toNumber(),
                (w * 0.39).toNumber(), (h * 0.51).toNumber()];
        red = [(w * 0.53).toNumber(), blue[1], blue[2], blue[3]];
        reset = [(w * 0.30).toNumber(), (h * 0.73).toNumber(),
                 (w * 0.40).toNumber(), (h * 0.15).toNumber()];
    }

    function zoneAt(x, y) {
        if (_contains(reset, x, y)) { return ZONE_RESET; }
        if (_contains(blue, x, y)) { return ZONE_BLUE; }
        if (_contains(red, x, y)) { return ZONE_RED; }
        return ZONE_NONE;
    }

    function _contains(rect as Lang.Array<Lang.Number>, x, y) {
        return x >= rect[0] && x < rect[0] + rect[2] &&
               y >= rect[1] && y < rect[1] + rect[3];
    }
}
