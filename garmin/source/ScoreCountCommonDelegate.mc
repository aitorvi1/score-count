import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ScoreCountCommonDelegate extends WatchUi.BehaviorDelegate {
    const VIBRATION_STRENGTH = 50;
    const VIBRATION_MS = 80;

    var _model;
    var _layout;
    var _touch;

    function initialize(model, layout) {
        BehaviorDelegate.initialize();
        _model = model;
        _layout = layout;
        _touch = new TouchGesture();
    }

    function onTap(event) {
        var point = event.getCoordinates();
        return handleTap(point[0], point[1], System.getTimer());
    }

    function handleTap(x, y, now) {
        if (_touch.suppressTap(now)) { return true; }
        var zone = _layout.zoneAt(x, y);
        if (zone == ScoreLayout.ZONE_BLUE) {
            _finish(_model.addBluePoint());
        } else if (zone == ScoreLayout.ZONE_RED) {
            _finish(_model.addRedPoint());
        } else if (zone == ScoreLayout.ZONE_RESET) {
            _finish(_model.reset());
        }
        return zone != ScoreLayout.ZONE_NONE;
    }

    function onHold(event) {
        var point = event.getCoordinates();
        return handleHold(point[0], point[1]);
    }

    function handleHold(x, y) {
        if (!_touch.beginHold()) { return true; }
        var zone = _layout.zoneAt(x, y);
        if (zone == ScoreLayout.ZONE_BLUE) {
            _finish(_model.subtractBluePoint());
        } else if (zone == ScoreLayout.ZONE_RED) {
            _finish(_model.subtractRedPoint());
        }
        return true;
    }

    function onRelease(event) {
        return handleRelease(System.getTimer());
    }

    function handleRelease(now) {
        return _touch.release(now);
    }

    function _finish(changed) {
        if (!changed && !_model.hasStorageError()) { return; }
        WatchUi.requestUpdate();
        if (changed) { _vibrate(); }
    }

    function _vibrate() {
        if (!(Attention has :vibrate) || !(Attention has :VibeProfile)) { return; }
        var settings = System.getDeviceSettings();
        if (settings has :vibrateOn && !settings.vibrateOn) { return; }
        try {
            Attention.vibrate([new Attention.VibeProfile(VIBRATION_STRENGTH, VIBRATION_MS)]);
        } catch (error) {
            // A device's haptic failure must not invalidate a saved score.
            System.println("Score Count: vibration unavailable: " + error.getErrorMessage());
        }
    }
}
