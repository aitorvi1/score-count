import storage from '@system.storage';

const SCORE_KEY = 'frontenisScore';
let loaded = false;
let pendingActions = [];
const pendingWrites = [];
let writing = false;

function validScore(value) {
  return typeof value === 'number' && isFinite(value) && value >= 0 &&
    Math.floor(value) === value ? value : 0;
}

function writeNextScore() {
  if (writing || pendingWrites.length === 0) {
    return;
  }
  writing = true;
  storage.set({
    key: SCORE_KEY,
    value: pendingWrites.shift(),
    fail: function () {
      console.log('Frontenis Score: could not save scores');
    },
    complete: function () {
      writing = false;
      writeNextScore();
    }
  });
}

export default {
  data: {
    scoreA: 0,
    scoreB: 0
  },
  onInit() {
    loaded = false;
    pendingActions = [];
    storage.get({
      key: SCORE_KEY,
      default: '{"scoreA":0,"scoreB":0}',
      success: (value) => {
        let scores = {};
        try {
          scores = JSON.parse(value) || {};
        } catch (error) {
          console.log('Frontenis Score: invalid saved scores');
        }
        this.scoreA = validScore(scores.scoreA);
        this.scoreB = validScore(scores.scoreB);
      },
      fail: () => {
        this.scoreA = 0;
        this.scoreB = 0;
        console.log('Frontenis Score: could not load scores');
      },
      complete: () => {
        loaded = true;
        // Replay taps made while storage was still loading.
        const actions = pendingActions;
        pendingActions = [];
        actions.forEach((action) => this.changeScore(action));
      }
    });
  },
  changeScore(action) {
    if (!loaded) {
      pendingActions.push(action);
      return;
    }
    if (action === 'reset') {
      this.scoreA = 0;
      this.scoreB = 0;
    } else if (action === 'addA') {
      this.scoreA += 1;
    } else if (action === 'addB') {
      this.scoreB += 1;
    } else if (action === 'subtractA') {
      this.scoreA = Math.max(0, this.scoreA - 1);
    } else if (action === 'subtractB') {
      this.scoreB = Math.max(0, this.scoreB - 1);
    }
    pendingWrites.push(JSON.stringify({ scoreA: this.scoreA, scoreB: this.scoreB }));
    writeNextScore();
  },
  addPointA() {
    this.changeScore('addA');
  },
  addPointB() {
    this.changeScore('addB');
  },
  subtractPointA() {
    this.changeScore('subtractA');
  },
  subtractPointB() {
    this.changeScore('subtractB');
  },
  reset() {
    this.changeScore('reset');
  }
};
