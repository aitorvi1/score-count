import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Selected by Jungle; no runtime product checks.
class ScoreCountDelegate extends ScoreCountCommonDelegate {
    const INPUT_POLICY = "FULL_PHYSICAL";
    // Independent slots permit overlap; ENTER and START share slot 2.
    var _pressedAt as Lang.Array<Lang.Long or Null> = [null, null, null];

    function initialize(model, layout) {
        ScoreCountCommonDelegate.initialize(model, layout);
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

}
