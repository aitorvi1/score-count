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
function buttonsAndMultipleUndo(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var delegate = new RecordingDelegate(model, new ScoreLayout());
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 0l);
    Test.assert(shortPress(delegate, WatchUi.KEY_UP));
    Test.assert(shortPress(delegate, WatchUi.KEY_DOWN));
    Test.assert(shortPress(delegate, WatchUi.KEY_DOWN));
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 2l);
    Test.assert(shortPress(delegate, WatchUi.KEY_ENTER));
    Test.assert(shortPress(delegate, WatchUi.KEY_START));
    Test.assertEqual(model.getScoreRed(), 0l);
    shortPress(delegate, WatchUi.KEY_START);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getHistorySize(), 0);
    shortPress(delegate, WatchUi.KEY_START);
    Test.assertEqual(delegate.vibrations, 6);
    Test.assertEqual(store.writes, 6);
    return true;
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
    shortPress(delegate, WatchUi.KEY_START);
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
    shortPress(delegate, WatchUi.KEY_UP);
    store.failWrite = true;
    shortPress(delegate, WatchUi.KEY_DOWN);
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


function shortPress(delegate, key) {
    delegate.handleKeyPressed(key, 100);
    return delegate.handleKeyReleased(key, 200);
}

(:test)
function physicalThresholds(logger) {
    var keys = [WatchUi.KEY_UP, WatchUi.KEY_DOWN, WatchUi.KEY_START];
    var limits = [800, 800, 1500];
    for (var i = 0; i < keys.size(); i += 1) {
        for (var delta = -1; delta <= 0; delta += 1) {
            var store = new MemoryScoreStore();
            var model = new ScoreModel(store);
            model.addBluePoint();
            model.addRedPoint();
            var input = new RecordingDelegate(model, new ScoreLayout());
            Test.assert(input.handleKeyPressed(keys[i], 100));
            Test.assertEqual(store.writes, 2);
            Test.assert(input.handleKeyReleased(keys[i], 100 + limits[i] + delta));
            Test.assertEqual(store.writes, 3);
            Test.assertEqual(input.vibrations, 1);
            if (i == 0) {
                Test.assertEqual(model.getScoreBlue(), delta == -1 ? 2l : 0l);
                Test.assertEqual(model.getScoreRed(), 1l);
            } else if (i == 1) {
                Test.assertEqual(model.getScoreBlue(), 1l);
                Test.assertEqual(model.getScoreRed(), delta == -1 ? 2l : 0l);
            } else {
                Test.assertEqual(model.getScoreBlue(), delta == -1 ? 1l : 0l);
                Test.assertEqual(model.getScoreRed(), 0l);
                Test.assertEqual(model.getHistorySize(), delta == -1 ? 1 : 3);
            }
        }
    }
    return true;
}

(:test)
function repeatsExtraKeysAndReleasesAreInert(logger) {
    var keys = [WatchUi.KEY_UP, WatchUi.KEY_DOWN, WatchUi.KEY_START];
    var limits = [800, 800, 1500];
    for (var i = 0; i < keys.size(); i += 1) {
        var store = new MemoryScoreStore();
        var model = new ScoreModel(store);
        model.addBluePoint();
        model.addRedPoint();
        var input = new RecordingDelegate(model, new ScoreLayout());
        input.handleKeyReleased(keys[i], 0);
        input.handleKey(keys[i]);
        input.handleKeyPressed(keys[i], 100);
        input.handleKeyPressed(keys[i], 700);
        input.handleKey(keys[i]);
        Test.assertEqual(store.writes, 2);
        Test.assertEqual(input.vibrations, 0);
        input.handleKeyReleased(keys[i], 100 + limits[i]);
        input.handleKey(keys[i]);
        input.handleKeyReleased(keys[i], 200 + limits[i]);
        Test.assertEqual(store.writes, 3);
        Test.assertEqual(input.vibrations, 1);
        Test.assertEqual(model.getScoreBlue(), i == 1 ? 1l : 0l);
        Test.assertEqual(model.getScoreRed(), i == 0 ? 1l : 0l);
    }
    return true;
}

(:test)
function overlappingKeysKeepIndependentTimes(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    model.addBluePoint();
    var input = new RecordingDelegate(model, new ScoreLayout());
    input.handleKeyPressed(WatchUi.KEY_UP, 0);
    input.handleKeyPressed(WatchUi.KEY_DOWN, 400);
    input.handleKeyPressed(WatchUi.KEY_START, 600);
    input.handleKeyReleased(WatchUi.KEY_DOWN, 900); // + red
    input.handleKeyReleased(WatchUi.KEY_UP, 900); // - blue
    input.handleKeyReleased(WatchUi.KEY_ENTER, 1000); // undo - blue
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assertEqual(store.writes, 4);
    Test.assertEqual(input.vibrations, 3);
    return true;
}

(:test)
function enterStartAliasesShareOnePress(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    model.addBluePoint();
    var input = new RecordingDelegate(model, new ScoreLayout());
    input.handleKeyPressed(WatchUi.KEY_ENTER, 0);
    input.handleKeyPressed(WatchUi.KEY_START, 1400);
    input.handleKeyReleased(WatchUi.KEY_START, 1500);
    input.handleKeyReleased(WatchUi.KEY_ENTER, 1501);
    Test.assertEqual(store.writes, 2);
    Test.assertEqual(model.getHistorySize(), 2); // RESET, not UNDO
    Test.assertEqual(input.vibrations, 1);
    input.handleKeyPressed(WatchUi.KEY_START, 2000);
    input.handleKeyReleased(WatchUi.KEY_ENTER, 2100);
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(input.vibrations, 2);
    return true;
}

(:test)
function signedTimerOverflowKeepsThresholds(logger) {
    var keys = [WatchUi.KEY_UP, WatchUi.KEY_DOWN, WatchUi.KEY_START];
    var limits = [800, 800, 1500];
    for (var i = 0; i < keys.size(); i += 1) {
        for (var delta = -1; delta <= 0; delta += 1) {
            var store = new MemoryScoreStore();
            var model = new ScoreModel(store);
            model.addBluePoint();
            model.addRedPoint();
            var input = new RecordingDelegate(model, new ScoreLayout());
            input.handleKeyPressed(keys[i], 2147483600);
            input.handleKeyReleased(keys[i], (2147483600l + limits[i] + delta - 4294967296l).toNumber());
            Test.assertEqual(model.getScoreBlue(), i == 0 ? (delta == -1 ? 2l : 0l) : (i == 1 || delta == -1 ? 1l : 0l));
            Test.assertEqual(model.getScoreRed(), i == 1 ? (delta == -1 ? 2l : 0l) : (i == 0 ? 1l : 0l));
            Test.assertEqual(input.vibrations, 1);
        }
    }
    return true;
}

(:test)
function menuAndSecondaryBehaviorsNeverScore(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    model.addBluePoint();
    var input = new RecordingDelegate(model, new ScoreLayout());
    Test.assert(input.onMenu()); // no UP press: never infer one
    input.handleKey(WatchUi.KEY_MENU);
    input.handleKeyPressed(WatchUi.KEY_UP, 0);
    Test.assert(input.onPreviousPage());
    Test.assert(input.onMenu());
    Test.assert(input.onMenu());
    Test.assertEqual(store.writes, 1);
    Test.assertEqual(input.vibrations, 0);
    input.handleKeyReleased(WatchUi.KEY_UP, 800);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(store.writes, 2);
    Test.assertEqual(input.vibrations, 1);
    input.onMenu();
    input.handleKeyReleased(WatchUi.KEY_UP, 900);
    input.handleKeyPressed(WatchUi.KEY_DOWN, 1000);
    Test.assert(input.onNextPage());
    input.handleKeyReleased(WatchUi.KEY_DOWN, 1100);
    input.handleKeyPressed(WatchUi.KEY_START, 1200);
    Test.assert(input.onSelect());
    input.handleKeyReleased(WatchUi.KEY_START, 1300);
    Test.assertEqual(store.writes, 4);
    return true;
}

(:test)
function physicalZeroActionsAndResetUndoPersist(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var input = new RecordingDelegate(model, new ScoreLayout());
    var keys = [WatchUi.KEY_UP, WatchUi.KEY_DOWN, WatchUi.KEY_START];
    for (var i = 0; i < keys.size(); i += 1) {
        input.handleKeyPressed(keys[i], 0);
        input.handleKeyReleased(keys[i], 1500);
    }
    Test.assertEqual(model.getHistorySize(), 0);
    Test.assertEqual(store.writes, 0);
    Test.assertEqual(input.vibrations, 0);
    shortPress(input, WatchUi.KEY_UP);
    shortPress(input, WatchUi.KEY_DOWN);
    input.handleKeyPressed(WatchUi.KEY_START, 0);
    input.handleKeyReleased(WatchUi.KEY_START, 1500);
    Test.assertEqual(model.getHistorySize(), 3);
    input.handleKeyPressed(WatchUi.KEY_START, 0);
    input.handleKeyReleased(WatchUi.KEY_START, 1500);
    Test.assertEqual(model.getHistorySize(), 3);
    Test.assertEqual(store.writes, 3);
    Test.assertEqual(input.vibrations, 3);
    var restarted = new ScoreModel(store);
    var restartedInput = new RecordingDelegate(restarted, new ScoreLayout());
    shortPress(restartedInput, WatchUi.KEY_START);
    var again = new ScoreModel(store);
    Test.assertEqual(again.getScoreBlue(), 1l);
    Test.assertEqual(again.getScoreRed(), 1l);
    Test.assertEqual(again.getHistorySize(), 2);
    return true;
}

(:test)
function failedPhysicalLongActionsPreserveState(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    model.addBluePoint();
    model.addRedPoint();
    var input = new RecordingDelegate(model, new ScoreLayout());
    store.failWrite = true;
    var keys = [WatchUi.KEY_UP, WatchUi.KEY_DOWN, WatchUi.KEY_START];
    for (var i = 0; i < keys.size(); i += 1) {
        input.handleKeyPressed(keys[i], 0);
        input.handleKeyReleased(keys[i], 1500);
    }
    Test.assert(model.hasStorageError());
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assertEqual(model.getHistorySize(), 2);
    Test.assertEqual(store.writes, 2);
    Test.assertEqual(input.vibrations, 0);
    store.failWrite = false;
    shortPress(input, WatchUi.KEY_ENTER);
    Test.assertEqual(model.getScoreRed(), 0l);
    return true;
}

(:test)
function timerWrapFromNegativeToPositive(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    model.addBluePoint();
    var input = new RecordingDelegate(model, new ScoreLayout());
    input.handleKeyPressed(WatchUi.KEY_UP, -400);
    input.handleKeyReleased(WatchUi.KEY_UP, 399);
    Test.assertEqual(model.getScoreBlue(), 2l);
    input.handleKeyPressed(WatchUi.KEY_UP, -400);
    input.handleKeyReleased(WatchUi.KEY_UP, 400);
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(store.writes, 3);
    return true;
}
