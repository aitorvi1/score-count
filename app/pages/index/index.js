export default {
  data: {
    scoreA: 0,
    scoreB: 0
  },
  addPointA() {
    this.scoreA += 1;
  },
  addPointB() {
    this.scoreB += 1;
  },
  subtractPointA() {
    if (this.scoreA > 0) {
      this.scoreA -= 1;
    }
  },
  subtractPointB() {
    if (this.scoreB > 0) {
      this.scoreB -= 1;
    }
  },
  reset() {
    this.scoreA = 0;
    this.scoreB = 0;
  }
};
