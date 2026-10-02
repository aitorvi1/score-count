import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

(:test)
class MemoryScoreStore extends ScoreStore {
    var state = null;
    var failRead = false;
    var failWrite = false;
    var writes = 0;

    function initialize() {
        ScoreStore.initialize();
    }

    function read() {
        if (failRead) { throw new Lang.StorageFullException("Simulated read failure"); }
        return state;
    }

    function write(value) {
        if (failWrite) { throw new Lang.StorageFullException("Simulated write failure"); }
        state = value;
        writes += 1;
    }
}

(:test)
class RecordingDelegate extends ScoreCountDelegate {
    var vibrations = 0;

    function initialize(model, layout) {
        ScoreCountDelegate.initialize(model, layout);
    }

    function _vibrate() { vibrations += 1; }
}

function pressKey(delegate, key, duration) {
    // Exercise the same handlers as SDK callbacks, with action events both before
    // and after release. Neither action event is allowed to modify the score.
    return delegate.handleKeyPressed(key, 10000) &&
           delegate.handleKey(key) &&
           delegate.handleKeyReleased(key, 10000 + duration) &&
           delegate.handleKey(key);
}

(:test)
function buttonsAndMultipleUndo(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 0l);
    Test.assert(pressKey(delegate, WatchUi.KEY_UP, 100));
    Test.assert(pressKey(delegate, WatchUi.KEY_DOWN, 100));
    Test.assert(pressKey(delegate, WatchUi.KEY_DOWN, 100));
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 2l);
    Test.assert(pressKey(delegate, WatchUi.KEY_ENTER, 100));
    Test.assert(pressKey(delegate, WatchUi.KEY_START, 100));
    Test.assertEqual(model.getScoreRed(), 0l);
    pressKey(delegate, WatchUi.KEY_START, 100);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getHistorySize(), 0);
    pressKey(delegate, WatchUi.KEY_START, 100);
    Test.assertEqual(delegate.vibrations, 6);
    Test.assertEqual(store.writes, 6);
    return true;
}

(:test)
function garminKeysAndSwipesStayUnassigned(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    var keys = [WatchUi.KEY_ESC, WatchUi.KEY_LAP, WatchUi.KEY_LIGHT, WatchUi.KEY_MENU];
    for (var i = 0; i < keys.size(); i += 1) {
        Test.assert(!delegate.handleKeyPressed(keys[i], 100));
        Test.assert(!delegate.handleKey(keys[i]));
        Test.assert(!delegate.handleKeyReleased(keys[i], 2000));
    }
    Test.assertEqual(delegate.vibrations, 0);
    Test.assertEqual(store.writes, 0);
    return true;
}

(:test)
function touchActionsAndProtectedReset(logger) {
    var model = new ScoreModel(new MemoryScoreStore());
    var layout = new ScoreLayout();
    layout.resize(260, 260);
    var delegate = new RecordingDelegate(model, layout);
    Test.assert(!delegate.handleTap(130, 20, 0));
    Test.assert(delegate.handleTap(70, 120, 10));
    Test.assert(delegate.handleTap(190, 120, 20));
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assert(delegate.handleTap(130, 205, 30));
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    delegate.handleHold(70, 120);
    delegate.handleRelease(100);
    Test.assertEqual(model.getScoreBlue(), 0l);
    delegate.handleHold(190, 120);
    delegate.handleRelease(500);
    Test.assertEqual(model.getScoreRed(), 0l);
    var count = delegate.vibrations;
    delegate.handleHold(70, 120);
    delegate.handleRelease(1000);
    delegate.handleHold(190, 120);
    delegate.handleRelease(1400);
    Test.assertEqual(delegate.vibrations, count);
    Test.assertEqual(model.getHistorySize(), 4);
    delegate.handleTap(70, 120, 2000);
    delegate.handleTap(190, 120, 2100);
    delegate.handleHold(130, 205);
    delegate.handleRelease(2500);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 0l);
    pressKey(delegate, WatchUi.KEY_START, 100);
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    return true;
}

(:test)
function holdCannotBecomeAnIncrement(logger) {
    var model = new ScoreModel(new MemoryScoreStore());
    var layout = new ScoreLayout();
    layout.resize(260, 260);
    var delegate = new RecordingDelegate(model, layout);
    model.addBluePoint();
    model.addBluePoint();
    delegate.handleHold(70, 120);
    delegate.handleHold(70, 120);
    delegate.handleTap(70, 120, 100);
    Test.assertEqual(model.getScoreBlue(), 1l);
    delegate.handleRelease(1000);
    delegate.handleTap(70, 120, 1001);
    Test.assertEqual(model.getScoreBlue(), 1l);
    // The next genuine tap works even if Garmin never sends a duplicate tap.
    delegate.handleTap(70, 120, 1300);
    Test.assertEqual(model.getScoreBlue(), 2l);
    Test.assertEqual(delegate.vibrations, 2);
    return true;
}

(:test)
function resetAndUndoSurviveRestart(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    for (var i = 0; i < 12; i += 1) { model.addBluePoint(); }
    for (var i = 0; i < 8; i += 1) { model.addRedPoint(); }
    Test.assert(model.reset());
    var restarted = new ScoreModel(store);
    Test.assertEqual(restarted.getScoreBlue(), 0l);
    Test.assertEqual(restarted.getScoreRed(), 0l);
    Test.assert(restarted.undo());
    Test.assertEqual(restarted.getScoreBlue(), 12l);
    Test.assertEqual(restarted.getScoreRed(), 8l);
    var restartedAgain = new ScoreModel(store);
    Test.assertEqual(restartedAgain.getScoreBlue(), 12l);
    Test.assertEqual(restartedAgain.getScoreRed(), 8l);
    Test.assert(restartedAgain.undo());
    Test.assertEqual(restartedAgain.getScoreRed(), 7l);
    return true;
}

(:test)
function historyIsBoundedWithoutLimitingScore(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    for (var i = 0; i < 40; i += 1) { model.addBluePoint(); }
    var restarted = new ScoreModel(store);
    Test.assertEqual(restarted.getHistorySize(), 25);
    for (var i = 0; i < 25; i += 1) { Test.assert(restarted.undo()); }
    Test.assert(!restarted.undo());
    Test.assertEqual(restarted.getScoreBlue(), 15l);
    store.state = {"version" => 1, "scoreBlue" => 2147483647l,
                   "scoreRed" => 0l, "history" => []};
    var large = new ScoreModel(store);
    Test.assert(large.addBluePoint());
    Test.assertEqual(large.getScoreBlue(), 2147483648l);
    return true;
}

(:test)
function zeroActionsDoNotWriteOrVibrate(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    Test.assert(!model.subtractBluePoint());
    Test.assert(!model.subtractRedPoint());
    Test.assert(!model.reset());
    Test.assert(!model.undo());
    Test.assertEqual(store.writes, 0);
    Test.assertEqual(model.getHistorySize(), 0);
    return true;
}

(:test)
function failedWritesPreserveScoreAndUndo(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    pressKey(delegate, WatchUi.KEY_UP, 100);
    store.failWrite = true;
    pressKey(delegate, WatchUi.KEY_DOWN, 100);
    Test.assert(model.hasStorageError());
    Test.assertEqual(model.getScoreRed(), 0l);
    Test.assertEqual(model.getHistorySize(), 1);
    Test.assert(!model.reset());
    Test.assert(!model.undo());
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(delegate.vibrations, 1);
    store.failWrite = false;
    Test.assert(model.undo());
    Test.assert(!model.hasStorageError());
    Test.assertEqual(model.getScoreBlue(), 0l);
    return true;
}

(:test)
function malformedStorageAndReadFailure(logger) {
    var store = new MemoryScoreStore();
    store.state = {"version" => 1, "scoreBlue" => -2, "scoreRed" => 7,
                   "history" => [[-1, 7]]};
    var model = new ScoreModel(store);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 7l);
    Test.assertEqual(model.getHistorySize(), 0);
    store.state = {"version" => 1, "scoreBlue" => 3, "scoreRed" => 7,
                   "history" => [[0, 0], "invalid"]};
    model = new ScoreModel(store);
    Test.assertEqual(model.getScoreBlue(), 3l);
    Test.assertEqual(model.getHistorySize(), 0);
    store.failRead = true;
    var unreadable = new ScoreModel(store);
    Test.assert(unreadable.hasStorageError());
    Test.assert(!unreadable.addBluePoint());
    Test.assert(!unreadable.save());
    Test.assertEqual(store.writes, 0);
    return true;
}

(:test)
function layoutAdaptsAndKeepsSeparateTargets(logger) {
    var layout = new ScoreLayout();
    var sizes = [[240, 240], [260, 260], [390, 390], [416, 416], [360, 400]];
    for (var i = 0; i < sizes.size(); i += 1) {
        var w = sizes[i][0];
        var h = sizes[i][1];
        layout.resize(w, h);
        Test.assertEqual(layout.zoneAt(w * 0.27, h * 0.46), ScoreLayout.ZONE_BLUE);
        Test.assertEqual(layout.zoneAt(w * 0.72, h * 0.46), ScoreLayout.ZONE_RED);
        Test.assertEqual(layout.zoneAt(w * 0.5, h * 0.8), ScoreLayout.ZONE_RESET);
        Test.assertEqual(layout.zoneAt(w * 0.5, h * 0.5), ScoreLayout.ZONE_NONE);
        Test.assertEqual(layout.zoneAt(w * 0.5, h * 0.68), ScoreLayout.ZONE_NONE);
        Test.assertEqual(layout.zoneAt(0, 0), ScoreLayout.ZONE_NONE);
    }
    return true;
}

(:test)
function pointKeyThresholds(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    Test.assert(pressKey(delegate, WatchUi.KEY_UP, 799));
    Test.assert(pressKey(delegate, WatchUi.KEY_DOWN, 799));
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assert(pressKey(delegate, WatchUi.KEY_UP, 800));
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assert(pressKey(delegate, WatchUi.KEY_DOWN, 800));
    Test.assertEqual(model.getScoreRed(), 0l);
    Test.assertEqual(model.getHistorySize(), 4);
    Test.assertEqual(delegate.vibrations, 4);
    Test.assertEqual(store.writes, 4);
    return true;
}

(:test)
function startThresholdAndResetUndo(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    for (var i = 0; i < 12; i += 1) { model.addBluePoint(); }
    for (var i = 0; i < 8; i += 1) { model.addRedPoint(); }
    Test.assert(pressKey(delegate, WatchUi.KEY_ENTER, 1500));
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 0l);
    Test.assertEqual(model.getHistorySize(), 21);
    Test.assert(pressKey(delegate, WatchUi.KEY_START, 1499));
    Test.assertEqual(model.getScoreBlue(), 12l);
    Test.assertEqual(model.getScoreRed(), 8l);
    Test.assert(pressKey(delegate, WatchUi.KEY_START, 2000));
    var restarted = new ScoreModel(store);
    Test.assertEqual(restarted.getScoreBlue(), 0l);
    Test.assertEqual(restarted.getScoreRed(), 0l);
    Test.assert(restarted.undo());
    Test.assertEqual(restarted.getScoreBlue(), 12l);
    Test.assertEqual(restarted.getScoreRed(), 8l);
    Test.assertEqual(delegate.vibrations, 3);
    return true;
}

(:test)
function zeroLongKeysLeaveHistoryAndHapticsAlone(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    pressKey(delegate, WatchUi.KEY_UP, 3000);
    pressKey(delegate, WatchUi.KEY_DOWN, 3000);
    pressKey(delegate, WatchUi.KEY_START, 3000);
    Test.assertEqual(store.writes, 0);
    Test.assertEqual(delegate.vibrations, 0);
    Test.assertEqual(model.getHistorySize(), 0);
    model.addBluePoint();
    model.reset();
    // A zero score may still have useful UNDO history. A second reset preserves it.
    pressKey(delegate, WatchUi.KEY_ENTER, 1500);
    Test.assertEqual(store.writes, 2);
    Test.assertEqual(model.getHistorySize(), 2);
    Test.assertEqual(delegate.vibrations, 0);
    pressKey(delegate, WatchUi.KEY_ENTER, 100);
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(delegate.vibrations, 1);
    return true;
}

(:test)
function consecutiveLongKeysApplyExactlyOnce(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    for (var i = 0; i < 3; i += 1) {
        model.addBluePoint();
        model.addRedPoint();
    }
    for (var i = 0; i < 3; i += 1) {
        pressKey(delegate, WatchUi.KEY_UP, 1200);
        pressKey(delegate, WatchUi.KEY_DOWN, 1200);
        Test.assertEqual(model.getScoreBlue(), (2 - i).toLong());
        Test.assertEqual(model.getScoreRed(), (2 - i).toLong());
    }
    Test.assertEqual(delegate.vibrations, 6);
    Test.assertEqual(store.writes, 12);
    Test.assertEqual(model.getHistorySize(), 12);
    return true;
}

(:test)
function actionAndRepeatedReleaseEventsCannotDuplicateChanges(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    model.addBluePoint();
    delegate.handleKeyPressed(WatchUi.KEY_UP, 100);
    delegate.handleKey(WatchUi.KEY_UP);
    // Fenix/FR may synthesize MENU while the raw UP press is still active.
    Test.assert(!delegate.handleKey(WatchUi.KEY_MENU));
    delegate.handleKeyPressed(WatchUi.KEY_UP, 800);
    Test.assertEqual(model.getScoreBlue(), 1l);
    delegate.handleKeyReleased(WatchUi.KEY_UP, 900);
    delegate.handleKey(WatchUi.KEY_UP);
    delegate.handleKeyReleased(WatchUi.KEY_UP, 1000);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(delegate.vibrations, 1);
    Test.assertEqual(store.writes, 2);
    // Unpaired events must never guess a short press.
    delegate.handleKey(WatchUi.KEY_DOWN);
    delegate.handleKeyReleased(WatchUi.KEY_DOWN, 1200);
    Test.assertEqual(model.getScoreRed(), 0l);
    pressKey(delegate, WatchUi.KEY_DOWN, 100);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assertEqual(delegate.vibrations, 2);
    return true;
}

(:test)
function overlappingKeysAndStartAliases(logger) {
    var model = new ScoreModel(new MemoryScoreStore());
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    model.addRedPoint();
    delegate.handleKeyPressed(WatchUi.KEY_UP, 100);
    delegate.handleKeyPressed(WatchUi.KEY_DOWN, 120);
    delegate.handleKeyReleased(WatchUi.KEY_UP, 200);
    delegate.handleKeyReleased(WatchUi.KEY_DOWN, 920);
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 0l);
    delegate.handleKeyPressed(WatchUi.KEY_ENTER, 1000);
    delegate.handleKeyPressed(WatchUi.KEY_START, 2400);
    delegate.handleKeyReleased(WatchUi.KEY_START, 2500);
    delegate.handleKeyReleased(WatchUi.KEY_ENTER, 2501);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 0l);
    Test.assertEqual(delegate.vibrations, 3);
    pressKey(delegate, WatchUi.KEY_START, 100);
    Test.assertEqual(model.getScoreBlue(), 1l);
    return true;
}

(:test)
function keyDurationsSurviveTimerWraparound(logger) {
    var model = new ScoreModel(new MemoryScoreStore());
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    model.addBluePoint();
    model.addRedPoint();
    delegate.handleKeyPressed(WatchUi.KEY_UP, 2147483400);
    delegate.handleKeyReleased(WatchUi.KEY_UP, -2147483096); // 800 ms across signed wrap
    Test.assertEqual(model.getScoreBlue(), 0l);
    delegate.handleKeyPressed(WatchUi.KEY_DOWN, 2147483400);
    delegate.handleKeyReleased(WatchUi.KEY_DOWN, -2147483097); // 799 ms
    Test.assertEqual(model.getScoreRed(), 2l);
    delegate.handleKeyPressed(WatchUi.KEY_DOWN, -100);
    delegate.handleKeyReleased(WatchUi.KEY_DOWN, 700); // negative timer through zero
    Test.assertEqual(model.getScoreRed(), 1l);
    delegate.handleKeyPressed(WatchUi.KEY_START, 2147483400);
    delegate.handleKeyReleased(WatchUi.KEY_START, -2147482396); // 1500 ms
    Test.assertEqual(model.getScoreRed(), 0l);
    pressKey(delegate, WatchUi.KEY_START, 100);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assertEqual(delegate.vibrations, 5);
    return true;
}
