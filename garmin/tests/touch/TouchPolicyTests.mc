import Toybox.Test;
import Toybox.WatchUi;

(:test)
function selectedTouchPolicyAndPhysicalPassthrough(logger) {
    var store = new MemoryScoreStore();
    var model = new ScoreModel(store);
    model.addBluePoint();
    model.addRedPoint();
    var input = new RecordingDelegate(model, new ScoreLayout());
    Test.assertEqual(input.INPUT_POLICY, "TOUCH");
    logger.debug("Selected production policy: TOUCH");
    var keys = [WatchUi.KEY_ENTER, WatchUi.KEY_START, WatchUi.KEY_UP,
                WatchUi.KEY_DOWN, WatchUi.KEY_MENU, WatchUi.KEY_ESC,
                WatchUi.KEY_LAP, WatchUi.KEY_LIGHT];
    for (var i = 0; i < keys.size(); i += 1) {
        Test.assert(!input.handleKey(keys[i]));
        Test.assert(!input.handleKeyPressed(keys[i], 0));
        Test.assert(!input.handleKeyPressed(keys[i], 700));
        Test.assert(!input.handleKeyReleased(keys[i], 799));
        Test.assert(!input.handleKeyPressed(keys[i], 1000));
        Test.assert(!input.handleKeyReleased(keys[i], 2500));
        Test.assert(!input.handleKeyReleased(keys[i], 2501));
    }
    // Actual callbacks also pass through without inspecting or using the event.
    Test.assert(!input.onKey(null));
    Test.assert(!input.onKeyPressed(null));
    Test.assert(!input.onKeyReleased(null));
    Test.assert(!input.onMenu());
    Test.assert(!input.onBack());
    Test.assert(!input.onPreviousPage());
    Test.assert(!input.onNextPage());
    Test.assert(!input.onSelect());
    Test.assert(!input.onPreviousMode());
    Test.assert(!input.onNextMode());
    Test.assertEqual(model.getScoreBlue(), 1l);
    Test.assertEqual(model.getScoreRed(), 1l);
    Test.assertEqual(model.getHistorySize(), 2);
    Test.assertEqual(store.writes, 2);
    Test.assertEqual(input.vibrations, 0);
    return true;
}
