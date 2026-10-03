import Toybox.Test;
import Toybox.WatchUi;

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

(:test)
function selectedFullPhysicalPolicy(logger) {
    var input = new RecordingDelegate(new ScoreModel(new MemoryScoreStore()), new ScoreLayout());
    Test.assertEqual(input.INPUT_POLICY, "FULL_PHYSICAL");
    logger.debug("Selected production policy: FULL_PHYSICAL");
    return true;
}

(:test)
function physicalStartUndoesTouchResetAfterRestart(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    var layout = new ScoreLayout();
    layout.resize(260, 260);
    var input = new RecordingDelegate(model, layout);
    input.handleTap(70, 120, 0);
    input.handleTap(190, 120, 10);
    input.handleTap(130, 205, 20);
    Test.assertEqual(model.getScoreBlue(), 0l);
    Test.assertEqual(model.getScoreRed(), 0l);
    input.handleTap(130, 205, 30);
    Test.assertEqual(store.writes, 3);
    Test.assertEqual(input.vibrations, 3);
    var restarted = new ScoreModel(store);
    var restartedInput = new RecordingDelegate(restarted, layout);
    Test.assert(shortPress(restartedInput, WatchUi.KEY_START));
    Test.assertEqual(restarted.getScoreBlue(), 1l);
    Test.assertEqual(restarted.getScoreRed(), 1l);
    Test.assertEqual(restarted.getHistorySize(), 2);
    Test.assertEqual(store.writes, 4);
    Test.assertEqual(restartedInput.vibrations, 1);
    return true;
}
