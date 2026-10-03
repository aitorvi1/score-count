# Garmin Store release checklist

## Source state

- [ ] Work from `main`.
- [ ] `git pull --ff-only`.
- [ ] `git status --short` is empty.
- [ ] Version remains the intended Store version.
- [ ] UUID remains `854c3e8cfc934e58a1f4202b2b30de16`.
- [ ] Manifest still contains exactly 118 product IDs.
- [ ] Target split is still 89 FULL_PHYSICAL + 29 TOUCH.

## Validation

- [ ] Run `tools/verify_targets.py`.
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

- [ ] `bin/ScoreCount.iq` exists.
- [ ] Export produces no warnings/errors.
- [ ] `.iq` remains ignored by Git.
- [ ] Developer key remains outside the repository.
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

- [ ] Store icon: 500 × 500 px, sRGB.
- [ ] At least 10 px internal padding.
- [ ] No transparent or black background for the Store tile.
- [ ] No Garmin branding.
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
