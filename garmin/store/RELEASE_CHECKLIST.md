# Garmin Store release checklist

## Source state

- [x] Work from `main` (`ad6e46f936a056c288c1f21d20fb6bd909f0ec66`).
- [ ] `git pull --ff-only`.
- [x] `git status --short` is empty.
- [x] Version remains `1.0.0`.
- [x] UUID remains `854c3e8cfc934e58a1f4202b2b30de16`.
- [x] Manifest contains exactly 118 product IDs.
- [x] Target split is 89 FULL_PHYSICAL + 29 TOUCH.

## Validation

- [x] `tools/verify_targets.py` PASS.
- [ ] Rebuild release targets when source/configuration changed.
- [ ] Rebuild native tests when source/configuration changed.
- [ ] Confirm 0 compiler warnings and 0 compiler errors.
- [ ] Confirm native tests pass.
- [ ] Confirm representative screenshots are from the final release build.
- [ ] Keep the physical-hardware limitations documented.

## Export

From `score-count/garmin/`:

```sh
SDK="$(cat "$HOME/.Garmin/ConnectIQ/current-sdk.cfg")"
python3 tools/build.py \
  --sdk "$SDK" \
  --key "$HOME/.garmin-connectiq-key/developer_key.der" \
  --export
```

Then record locally:

```sh
ls -lh bin/ScoreCount.iq
sha256sum bin/ScoreCount.iq
```

- [x] `bin/ScoreCount.iq` exists.
- [x] Export produces 0 warnings / 0 errors.
- [x] `.iq` remains ignored by Git.
- [x] Developer key remains outside the repository.
- [ ] Keep the same developer key for future Store updates.

## Store metadata

- [ ] Name: Score Count.
- [ ] Spanish description reviewed.
- [ ] English description reviewed.
- [ ] Version notes reviewed.
- [ ] Support URL works.
- [ ] Privacy-policy URL works.
- [ ] No claims of physical validation beyond what has actually been tested.

## Assets

- [x] Definitive Store icon: `assets/score-count-store-icon-500.png` — 500 × 500 PNG, RGB, embedded sRGB profile, no transparency.
- [x] At least 10 px internal padding: light background preserved around the entire perimeter.
- [x] No transparent or black background for the Store tile.
- [x] No Garmin branding in the Store icon.
- [x] Original composition and proportions preserved with LANCZOS; no crop or added text.
- [x] Visual inspection at 500, 128 and 64 px: recognizable frontón, distinct blue/red cards, legible zeros, no clipping.
- [x] Store-only asset; on-watch launcher resources unchanged.
- [ ] Screenshots come from the final release build.
- [ ] Include representative round and rectangular layouts.
- [ ] Hero image, if used: 1440 × 720 px.

## Submission

- [ ] Upload the final `.iq` to the Connect IQ Store developer portal.
- [ ] Wait for binary validation.
- [ ] Complete listing text and screenshots.
- [ ] Preview the Store page.
- [ ] Submit for Garmin review.
- [ ] Do not present the app as Garmin-certified or endorsed.
