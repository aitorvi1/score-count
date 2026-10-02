import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ScoreCountDelegate extends WatchUi.BehaviorDelegate {
    const VIBRATION_STRENGTH = 50;
    const VIBRATION_MS = 80;

    var _model;
    var _layout;
    var _touch;
    // Independent slots permit overlap; ENTER and START share slot 2.
    var _pressedAt as Lang.Array<Lang.Long or Null> = [null, null, null];

    function initialize(model, layout) {
        BehaviorDelegate.initialize();
        _model = model;
        _layout = layout;
        _touch = new TouchGesture();
    }

    function onKey(event) {
        return handleKey(event.getKey());
    }

    function handleKey(key) {
        // Garmin may also deliver a behavior/onKey for the same physical press.
        // Only release is allowed to modify the score.
        return _keySlot(key) >= 0 || key == WatchUi.KEY_MENU;
    }

    function onKeyPressed(event) {
        return handleKeyPressed(event.getKey(), System.getTimer());
    }

    function onKeyReleased(event) {
        return handleKeyReleased(event.getKey(), System.getTimer());
    }

    function _keySlot(key) {
        if (key == WatchUi.KEY_UP) { return 0; }
        if (key == WatchUi.KEY_DOWN) { return 1; }
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) { return 2; }
        return -1;
    }

    function handleKeyPressed(key, now) {
        var slot = _keySlot(key);
        if (slot < 0) { return false; }
        // Auto-repeat and duplicate presses must preserve the original timestamp.
        if (_pressedAt[slot] == null) { _pressedAt[slot] = now.toLong(); }
        return true;
    }

    function handleKeyReleased(key, now) {
        var slot = _keySlot(key);
        if (slot < 0) { return false; }
        var started = _pressedAt[slot];
        if (started == null) { return true; }
        // Clear before dispatch: repeated releases, including aliases, are inert.
        _pressedAt[slot] = null;
        var elapsed = now.toLong() - started;
        // getTimer is a signed 32-bit millisecond counter. Widen BEFORE
        // subtracting, then unwrap one full counter cycle in Long arithmetic.
        if (elapsed < 0l) { elapsed += 4294967296l; }
        if (slot == 0) {
            _finish(elapsed >= 800l ? _model.subtractBluePoint() : _model.addBluePoint());
        } else if (slot == 1) {
            _finish(elapsed >= 800l ? _model.subtractRedPoint() : _model.addRedPoint());
        } else {
            _finish(elapsed >= 1500l ? _model.reset() : _model.undo());
        }
        return true;
    }

    // Consume secondary physical behaviors while the corresponding key is down.
    // Otherwise let touch/swipes reach their basic handlers without score changes.
    function onPreviousPage() { return _pressedAt[0] != null; }
    function onNextPage() { return _pressedAt[1] != null; }
    function onSelect() { return _pressedAt[2] != null; }
    function onBack() { return false; }

    function onMenu() {
        // UP/MENU hold can generate this before release. Consume it without
        // opening a view, changing the score, or discarding the UP timestamp.
        // A standalone MENU is also inert: never invent a missing UP press.
        return true;
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
