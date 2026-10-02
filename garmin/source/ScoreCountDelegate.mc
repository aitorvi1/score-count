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
        if (key == WatchUi.KEY_UP) {
            _finish(_model.addBluePoint());
        } else if (key == WatchUi.KEY_DOWN) {
            _finish(_model.addRedPoint());
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _finish(_model.undo());
        } else if (key == WatchUi.KEY_MENU) {
            // Raw-key fallback for profiles without an onMenu behavior mapping.
            return onMenu();
        } else {
            // BACK/ESC, LAP and LIGHT retain Garmin's standard behavior.
            return false;
        }
        return true;
    }

    // Returning false lets physical keys reach onKey and touch reach onTap/onSwipe.
    // These behaviors must never modify the score: swipes also map to them.
    function onPreviousPage() { return false; }
    function onNextPage() { return false; }
    function onSelect() { return false; }
    function onBack() { return false; }

    function onMenu() {
        var menu = new WatchUi.Menu();
        menu.setTitle(Rez.Strings.AppName);
        menu.addItem(Rez.Strings.SubtractBlue, :subtractBlue);
        menu.addItem(Rez.Strings.SubtractRed, :subtractRed);
        menu.addItem(Rez.Strings.ResetScore, :resetScore);
        _pushMenu(menu, new ScoreCountMenuDelegate(self));
        // Handled behaviors do not fall through to onKey(KEY_MENU).
        return true;
    }

    function handleMenuItem(item) {
        if (item != :subtractBlue && item != :subtractRed && item != :resetScore) {
            return false;
        }
        if (item == :subtractBlue) {
            _finish(_model.subtractBluePoint());
        } else if (item == :subtractRed) {
            _finish(_model.subtractRedPoint());
        } else if (item == :resetScore) {
            // A normal selection dismisses Menu. When pushing another view, close
            // it explicitly so cancelling Confirmation returns to the score.
            _closeMenu();
            _pushResetConfirmation(new ScoreResetConfirmationDelegate(self));
        }
        return true;
    }

    function handleResetResponse(response) {
        // Confirmation closes itself. Never pop the score view here.
        if (response == WatchUi.CONFIRM_YES) { _finish(_model.reset()); }
        return true;
    }

    function _pushMenu(menu, delegate) {
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function _closeMenu() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function _pushResetConfirmation(delegate) {
        var message = WatchUi.loadResource(Rez.Strings.ConfirmReset) as Lang.String;
        WatchUi.pushView(new WatchUi.Confirmation(message), delegate, WatchUi.SLIDE_IMMEDIATE);
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
