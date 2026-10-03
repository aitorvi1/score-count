// Garmin normally sends hold -> release, without tap. Guard against duplicate
// hold notifications and a spurious tap near release, without a sticky flag.
class TouchGesture {
    const RELEASE_GUARD_MS = 200;

    var _holding = false;
    var _releasedAt = null;

    function beginHold() {
        if (_holding) { return false; }
        _holding = true;
        _releasedAt = null;
        return true;
    }

    function release(now) {
        var wasHolding = _holding;
        _holding = false;
        if (wasHolding) { _releasedAt = now; }
        return wasHolding;
    }

    function suppressTap(now) {
        if (_holding) { return true; }
        if (_releasedAt == null) { return false; }
        var elapsed = now - _releasedAt;
        if (elapsed >= 0 && elapsed <= RELEASE_GUARD_MS) { return true; }
        _releasedAt = null;
        return false;
    }
}
