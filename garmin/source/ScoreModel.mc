import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

// This small boundary lets native Monkey C tests exercise failed writes safely.
class ScoreStore {
    const STORAGE_KEY = "scoreCount.state.v1";

    function initialize() {}

    function read() {
        return Application.Storage.getValue(STORAGE_KEY);
    }

    function write(state) {
        Application.Storage.setValue(STORAGE_KEY, state);
    }
}

class ScoreModel {
    const HISTORY_LIMIT = 25;
    const SCHEMA_VERSION = 1;

    var _store as ScoreStore;
    var _scoreBlue = 0l;
    var _scoreRed = 0l;
    var _history as Lang.Array<Lang.Array<Lang.Long>> = [];
    var _storageError = false;
    var _loadFailed = false;

    function initialize(store as ScoreStore) {
        _store = store;
        _load();
    }

    function getScoreBlue() { return _scoreBlue; }
    function getScoreRed() { return _scoreRed; }
    function getHistorySize() { return _history.size(); }
    function hasStorageError() { return _storageError; }

    function addBluePoint() {
        return _change(_scoreBlue + 1l, _scoreRed);
    }

    function addRedPoint() {
        return _change(_scoreBlue, _scoreRed + 1l);
    }

    function subtractBluePoint() {
        return _scoreBlue > 0l && _change(_scoreBlue - 1l, _scoreRed);
    }

    function subtractRedPoint() {
        return _scoreRed > 0l && _change(_scoreBlue, _scoreRed - 1l);
    }

    function reset() {
        return _change(0l, 0l);
    }

    function undo() {
        var count = _history.size();
        if (count == 0) {
            return false;
        }
        var previous = _history[count - 1];
        return _commit(previous[0], previous[1], _history.slice(0, count - 1));
    }

    function save() {
        if (_loadFailed) {
            return false;
        }
        return _write(_scoreBlue, _scoreRed, _history);
    }

    function _change(blue, red) {
        if (blue < 0l || red < 0l || (blue == _scoreBlue && red == _scoreRed)) {
            return false;
        }
        var history = _history.slice(0, _history.size());
        if (history.size() == HISTORY_LIMIT) {
            history = history.slice(1, history.size());
        }
        history.add([_scoreBlue, _scoreRed]);
        return _commit(blue, red, history);
    }

    function _commit(blue, red, history) {
        // Publish the new state only after storage accepts the complete snapshot.
        // A failed write cannot leave a displayed score that will vanish on exit.
        if (_loadFailed || !_write(blue, red, history)) {
            return false;
        }
        _scoreBlue = blue;
        _scoreRed = red;
        _history = history;
        return true;
    }

    function _write(blue, red, history) {
        try {
            _store.write({"version" => SCHEMA_VERSION,
                          "scoreBlue" => blue, "scoreRed" => red,
                          "history" => history});
            _storageError = false;
            return true;
        } catch (error) {
            _storageError = true;
            System.println("Score Count: storage write failed: " + error.getErrorMessage());
            return false;
        }
    }

    function _validScore(value) {
        return (value instanceof Lang.Number || value instanceof Lang.Long) && value >= 0;
    }

    function _load() {
        try {
            var state = _store.read();
            if (!(state instanceof Lang.Dictionary) || state["version"] != SCHEMA_VERSION) {
                return;
            }
            var blue = state["scoreBlue"];
            var red = state["scoreRed"];
            if (_validScore(blue)) { _scoreBlue = blue.toLong(); }
            if (_validScore(red)) { _scoreRed = red.toLong(); }

            var history = state["history"];
            if (!_validScore(blue) || !_validScore(red) || !(history instanceof Lang.Array)) {
                return;
            }
            var first = history.size() > HISTORY_LIMIT ? history.size() - HISTORY_LIMIT : 0;
            for (var i = first; i < history.size(); i += 1) {
                var pair = history[i];
                if (!(pair instanceof Lang.Array) || pair.size() != 2 ||
                    !_validScore(pair[0]) || !_validScore(pair[1])) {
                    _history = [];
                    return;
                }
                _history.add([pair[0].toLong(), pair[1].toLong()]);
            }
        } catch (error) {
            // Preserve unreadable storage instead of overwriting it with 0–0.
            _storageError = true;
            _loadFailed = true;
            System.println("Score Count: storage read failed: " + error.getErrorMessage());
        }
    }
}
