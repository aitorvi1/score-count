import vibrator from '@system.vibrator';
import file from '@system.file';

const SAVE_DIR = 'internal://app/save';
const SAVE_FILE = 'internal://app/save/score.txt';

let writing = false;
let pendingValue = null;

function doWriteScore(value) {
  writing = true;

  file.writeText({
    uri: SAVE_FILE,
    text: value,
    encoding: 'UTF-8',
    append: false,

    success: function () {
    },

    fail: function (data, code) {
      console.log('Score save failed: ' + code);
    },

    complete: function () {
      writing = false;

      if (pendingValue !== null) {
        const next = pendingValue;
        pendingValue = null;
        doWriteScore(next);
      }
    }
  });
}

function writeScore(value) {
  if (writing) {
    pendingValue = value;
    return;
  }

  file.mkdir({
    uri: SAVE_DIR,
    recursive: true,

    success: function () {
      doWriteScore(value);
    },

    fail: function () {
      file.access({
        uri: SAVE_DIR,

        success: function () {
          doWriteScore(value);
        },

        fail: function (data, code) {
          console.log('Save directory error: ' + code);
        }
      });
    }
  });
}

export default {
  data: {
    scoreA: 0,
    scoreB: 0,
    ignoreNextTapA: false,
    ignoreNextTapB: false
  },

  onInit() {
    file.readText({
      uri: SAVE_FILE,
      encoding: 'UTF-8',

      success: (data) => {
        const value = data.text;
        const parts = value.split(',');

        if (parts.length === 2) {
          const a = parseInt(parts[0]);
          const b = parseInt(parts[1]);

          this.scoreA = isNaN(a) ? 0 : a;
          this.scoreB = isNaN(b) ? 0 : b;
        }
      },

      fail: () => {
        this.scoreA = 0;
        this.scoreB = 0;
      }
    });
  },

  saveScore() {
    writeScore(
      String(this.scoreA) + ',' + String(this.scoreB)
    );
  },

  vibrate() {
    vibrator.vibrate({
      mode: 'short'
    });
  },

  addPointA() {
    if (this.ignoreNextTapA) {
      this.ignoreNextTapA = false;
      return;
    }

    this.scoreA += 1;
    this.saveScore();
    this.vibrate();
  },

  addPointB() {
    if (this.ignoreNextTapB) {
      this.ignoreNextTapB = false;
      return;
    }

    this.scoreB += 1;
    this.saveScore();
    this.vibrate();
  },

  subtractPointA() {
    this.ignoreNextTapA = true;

    if (this.scoreA > 0) {
      this.scoreA -= 1;
      this.saveScore();
      this.vibrate();
    }
  },

  subtractPointB() {
    this.ignoreNextTapB = true;

    if (this.scoreB > 0) {
      this.scoreB -= 1;
      this.saveScore();
      this.vibrate();
    }
  },

  reset() {
    this.scoreA = 0;
    this.scoreB = 0;
    this.saveScore();
    this.vibrate();
  }
};
