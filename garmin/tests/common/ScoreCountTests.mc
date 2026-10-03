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

(:test)
function garminKeysAndNavigationStayUnassigned(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    var keys = [WatchUi.KEY_ESC, WatchUi.KEY_LAP, WatchUi.KEY_LIGHT];
    for (var i = 0; i < keys.size(); i += 1) {
        Test.assert(!delegate.handleKey(keys[i]));
        Test.assert(!delegate.handleKeyPressed(keys[i], 0));
        Test.assert(!delegate.handleKeyReleased(keys[i], 2000));
    }
    Test.assert(!delegate.onBack());
    Test.assert(!delegate.onPreviousPage());
    Test.assert(!delegate.onNextPage());
    Test.assert(!delegate.onSelect());
    Test.assertEqual(delegate.vibrations, 0);
    Test.assertEqual(store.writes, 0);
    return true;
}

(:test)
function touchActionsAndTapReset(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var layout = new ScoreLayout();
    layout.resize(260, 260);
    var input = new RecordingDelegate(model, layout);
    Test.assert(!input.handleTap(130, 20, 0));
    input.handleTap(70, 120, 10);
    input.handleTap(190, 120, 20);
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assert(input.handleTap(130, 205, 30));
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 0l);
    Test.assertEqual(store.writes, 3);
    Test.assertEqual(input.vibrations, 3);
    Test.assertEqual(model.getHistorySize(), 3);
    // Further lower taps are RESET, never an undo of the saved state.
    input.handleTap(130, 205, 40);
    input.handleTap(130, 205, 50);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 0l);
    Test.assertEqual(store.writes, 3);
    Test.assertEqual(input.vibrations, 3);
    Test.assertEqual(model.getHistorySize(), 3);
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
    var layout = new ScoreLayout();
    layout.resize(260, 260);
    var delegate = new RecordingDelegate(model, layout);
    delegate.handleTap(70, 120, 0);
    store.failWrite = true;
    delegate.handleTap(190, 120, 10);
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
function lowerTapResetAndPersistence(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var layout = new ScoreLayout();
    layout.resize(260, 260);
    var input = new RecordingDelegate(model, layout);
    input.handleTap(70, 120, 0);
    input.handleTap(190, 120, 10);
    input.handleTap(130, 205, 20);
    Test.assertEqual(store.writes, 3);
    Test.assertEqual(input.vibrations, 3);
    var restarted = new ScoreModel(store);
    Test.assertEqual(restarted.getScoreBlue(), 0l);
    Test.assertEqual(restarted.getScoreRed(), 0l);
    Test.assertEqual(restarted.getHistorySize(), 3);
    var restartedInput = new RecordingDelegate(restarted, layout);
    restartedInput.handleTap(130, 205, 30);
    Test.assertEqual(store.writes, 3);
    Test.assertEqual(restartedInput.vibrations, 0);
    Test.assertEqual(restarted.getHistorySize(), 3);
    return true;
}

(:test)
function touchZeroActionsDoNotWriteOrVibrate(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var layout = new ScoreLayout();
    layout.resize(260, 260);
    var input = new RecordingDelegate(model, layout);
    input.handleTap(130, 205, 0);
    input.handleHold(70, 120);
    input.handleRelease(100);
    input.handleHold(190, 120);
    input.handleRelease(500);
    input.handleTap(130, 205, 1200);
    Test.assertEqual(store.writes, 0);
    Test.assertEqual(input.vibrations, 0);
    Test.assertEqual(model.getHistorySize(), 0);
    return true;
}

(:test)
function touchTeamsSubtractExactlyOnce(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var layout = new ScoreLayout();
    layout.resize(260, 260);
    var input = new RecordingDelegate(model, layout);
    input.handleTap(70, 120, 0);
    input.handleTap(70, 120, 10);
    input.handleTap(190, 120, 20);
    input.handleTap(190, 120, 30);
    input.handleHold(70, 120);
    input.handleHold(70, 120);
    input.handleRelease(100);
    input.handleTap(70, 120, 101);
    input.handleHold(190, 120);
    input.handleHold(190, 120);
    input.handleRelease(500);
    input.handleTap(190, 120, 501);
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assertEqual(store.writes, 6);
    Test.assertEqual(input.vibrations, 6);
    return true;
}
