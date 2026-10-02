import Toybox.Application;

class ScoreCountApp extends Application.AppBase {
    var _model;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        _model = new ScoreModel(new ScoreStore());
    }

    function getInitialView() {
        var layout = new ScoreLayout();
        return [new ScoreCountView(_model, layout),
                new ScoreCountDelegate(_model, layout)];
    }

    function onStop(state) {
        // Each action is already saved; this also retries a transient write failure.
        _model.save();
    }
}
