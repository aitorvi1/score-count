// Selected by Jungle. Every physical event remains available to Garmin.
class ScoreCountDelegate extends ScoreCountCommonDelegate {
    const INPUT_POLICY = "TOUCH";

    function initialize(model, layout) {
        ScoreCountCommonDelegate.initialize(model, layout);
    }

    function onKey(event) { return false; }
    function onKeyPressed(event) { return false; }
    function onKeyReleased(event) { return false; }
    function handleKey(key) { return false; }
    function handleKeyPressed(key, now) { return false; }
    function handleKeyReleased(key, now) { return false; }
    function onMenu() { return false; }
    function onBack() { return false; }
    function onPreviousPage() { return false; }
    function onNextPage() { return false; }
    function onPreviousMode() { return false; }
    function onNextMode() { return false; }
    function onSelect() { return false; }
}
