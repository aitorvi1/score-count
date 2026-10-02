import Toybox.WatchUi;

class ScoreCountMenuDelegate extends WatchUi.MenuInputDelegate {
    var _input;

    function initialize(input) {
        MenuInputDelegate.initialize();
        _input = input;
    }

    function onMenuItem(item) {
        _input.handleMenuItem(item);
    }
}

class ScoreResetConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    var _input;

    function initialize(input) {
        ConfirmationDelegate.initialize();
        _input = input;
    }

    function onResponse(response) {
        return _input.handleResetResponse(response);
    }
}
