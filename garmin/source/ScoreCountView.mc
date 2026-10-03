import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ScoreCountView extends WatchUi.View {
    const BLUE = 0x0055AA;
    const RED = 0xAA0000;

    var _model as ScoreModel;
    var _layout as ScoreLayout;
    var _resetName;
    var _saveError;

    function initialize(model as ScoreModel, layout as ScoreLayout) {
        View.initialize();
        _model = model;
        _layout = layout;
        _resetName = WatchUi.loadResource(Rez.Strings.Reset);
        _saveError = WatchUi.loadResource(Rez.Strings.SaveError);
    }

    function onLayout(dc) {
        _layout.resize(dc.getWidth(), dc.getHeight());
    }

    function onUpdate(dc) {
        _layout.resize(dc.getWidth(), dc.getHeight());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (_model.hasStorageError()) {
            var font = _fitFont(dc, _saveError, _layout.width * 0.70, _layout.height * 0.10,
                                [Graphics.FONT_SMALL, Graphics.FONT_TINY]);
            dc.drawText(_layout.width / 2, _layout.height * 0.09, font, _saveError,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        _drawTeam(dc, _layout.blue, BLUE, _model.getScoreBlue());
        _drawTeam(dc, _layout.red, RED, _model.getScoreRed());

        var reset = _layout.reset;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(reset[0], reset[1], reset[2], reset[3], _layout.width * 0.025);
        var resetFont = _fitFont(dc, _resetName, reset[2] * 0.88, reset[3] * 0.90,
                                [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY]);
        dc.drawText(reset[0] + reset[2] / 2, reset[1] + reset[3] / 2,
                    resetFont, _resetName,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function _drawTeam(dc as Graphics.Dc, rect as Lang.Array<Lang.Number>, color, score) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(rect[0], rect[1], rect[2], rect[3], _layout.width * 0.055);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        _drawScore(dc, rect, score.toString());
    }

    function _drawScore(dc as Graphics.Dc, rect as Lang.Array<Lang.Number>, text as Lang.String) {
        var width = rect[2] * 0.90;
        var height = rect[3] * 0.98;
        var fonts = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT,
                     Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD,
                     Graphics.FONT_LARGE, Graphics.FONT_MEDIUM,
                     Graphics.FONT_SMALL, Graphics.FONT_TINY];
        var font = _fitFont(dc, text, width, height, fonts);
        var centerX = rect[0] + rect[2] / 2;
        var centerY = rect[1] + rect[3] / 2;
        if (dc.getTextWidthInPixels(text, font) <= width) {
            dc.drawText(centerX, centerY, font, text,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        // Native integer scores have no sporting maximum. Very long values wrap
        // rather than disappearing beyond the team card's bounds.
        var digits = text.length();
        while (digits > 1 && dc.getTextWidthInPixels(text.substring(0, digits), font) > width) {
            digits -= 1;
        }
        var lines = ((text.length() + digits - 1) / digits).toNumber();
        var lineHeight = dc.getFontHeight(font);
        for (var i = 0; i < lines; i += 1) {
            var end = (i + 1) * digits;
            if (end > text.length()) { end = text.length(); }
            dc.drawText(centerX, centerY + (i - (lines - 1) / 2.0) * lineHeight,
                        font, text.substring(i * digits, end),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function _fitFont(dc as Graphics.Dc, text, width, height, fonts as Lang.Array<Graphics.FontType>) {
        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getTextWidthInPixels(text, fonts[i]) <= width &&
                dc.getFontHeight(fonts[i]) <= height) {
                return fonts[i];
            }
        }
        return fonts[fonts.size() - 1];
    }
}
