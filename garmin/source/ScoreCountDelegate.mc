import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ScoreCountDelegate extends WatchUi.InputDelegate {
    const VIBRATION_STRENGTH = 50;
    const VIBRATION_MS = 80;
    static const POINT_HOLD_MS = 800;
    static const RESET_HOLD_MS = 1500;
    const TIMER_WRAP_MS = 4294967296l;

    var _model;
    var _layout;
    var _touch;
    var _pressedAt as Lang.Array<Lang.Number or Null> = [null, null, null];

    function initialize(model, layout) {
        InputDelegate.initialize();
        _model = model;
        _layout = layout;
        _touch = new TouchGesture();
    }

    function onKey(event) {
        return handleKey(event.getKey());
    }

    function handleKey(key) {
        // Garmin can send this action event before release, including on key down.
        // Only onKeyReleased changes scores; consuming it prevents double actions.
        return _keyIndex(key) >= 0;
    }

    function onKeyPressed(event) {
        return handleKeyPressed(event.getKey(), System.getTimer());
    }

    function handleKeyPressed(key, now) {
        var index = _keyIndex(key);
        if (index < 0) { return false; }
        // Auto-repeat must not restart the duration of the original press.
        if (_pressedAt[index] == null) { _pressedAt[index] = now; }
        return true;
    }

    function onKeyReleased(event) {
        return handleKeyReleased(event.getKey(), System.getTimer());
    }

    function handleKeyReleased(key, now) {
        var index = _keyIndex(key);
        if (index < 0) { return false; }
        var startedAt = _pressedAt[index];
        _pressedAt[index] = null;
        if (startedAt == null) { return true; }

        // getTimer is a signed 32-bit millisecond counter. Widen before subtracting
        // and account for its wrap from positive to negative values after boot.
        var elapsed = now.toLong() - startedAt.toLong();
        if (elapsed < 0) { elapsed += TIMER_WRAP_MS; }
        if (index == 0) {
            _finish(elapsed >= POINT_HOLD_MS ? _model.subtractBluePoint() : _model.addBluePoint());
        } else if (index == 1) {
            _finish(elapsed >= POINT_HOLD_MS ? _model.subtractRedPoint() : _model.addRedPoint());
        } else {
            _finish(elapsed >= RESET_HOLD_MS ? _model.reset() : _model.undo());
        }
        return true;
    }

    function _keyIndex(key) {
        if (key == WatchUi.KEY_UP) { return 0; }
        if (key == WatchUi.KEY_DOWN) { return 1; }
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) { return 2; }
        // ESC/BACK, LAP, LIGHT and MENU retain Garmin's standard behavior.
        return -1;
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
        }
        // A short tap on RESET is consumed and has no effect.
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
        } else if (zone == ScoreLayout.ZONE_RESET) {
            _finish(_model.reset());
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
