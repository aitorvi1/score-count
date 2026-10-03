# Connect IQ Store release prep

This folder contains the publication material for the Garmin version of **Score Count**.

## Release target

- App name: **Score Count**
- Version: **1.0.0**
- UUID: `854c3e8cfc934e58a1f4202b2b30de16`
- Declared products: **118**
- Input policies: **89 FULL_PHYSICAL + 29 TOUCH**
- Permissions: none
- Languages: Spanish and English

The app stores score state and up to 25 history entries locally on the watch. It does not use GPS, network access, sensors, cloud services or advertising.

## Files in this folder

- [LISTING_ES.md](LISTING_ES.md): Spanish Store copy.
- [LISTING_EN.md](LISTING_EN.md): English Store copy.
- [PRIVACY.md](PRIVACY.md): privacy statement suitable for linking from the Store.
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md): final export and submission checklist.

## Final Store export

Always export from a clean `main` checkout using the same developer key used for future updates.

From `score-count/garmin/`:

```sh
git switch main
git pull --ff-only
git status --short

SDK="$(cat "$HOME/.Garmin/ConnectIQ/current-sdk.cfg")"
python3 tools/verify_targets.py --profiles "$HOME/.Garmin/ConnectIQ/Devices"
python3 tools/build.py --sdk "$SDK" \
  --key "$HOME/.garmin-connectiq-key/developer_key.der" \
  --export
```

Expected output:

```text
garmin/bin/ScoreCount.iq
```

The `.iq` is intentionally ignored by Git and must not be committed.

Final Store export verified from `main` commit `ad6e46f936a056c288c1f21d20fb6bd909f0ec66`:\n\n- File: `garmin/bin/ScoreCount.iq`\n- Size: **2,385,178 bytes**\n- SHA-256: `9327c77029bd5ccdafc396440108110439146e9ea152aa2751efe9a0f5782fe9`\n- Product IDs: **118**\n- Hardware variants: **201**\n- Export warnings/errors: **0 / 0**\n\nThe `.iq` remains ignored by Git. Re-export before submission only if the Garmin source/configuration or release metadata changes.

## Official Garmin submission flow

Garmin's documented first-release flow is:

1. Declare all supported products in the manifest.
2. Export the project to an `.iq` package.
3. Upload the `.iq` to the Connect IQ Store developer portal.
4. After binary validation, complete the listing description and screenshots.
5. Submit for Garmin review.

Official submission guide:
https://developer.garmin.com/connect-iq/submit-an-app/

## Store assets

Garmin's current Connect IQ brand guidance specifies:

### Store app icon

- 500 × 500 px
- sRGB
- keep at least 10 px of padding around the artwork
- avoid black or transparent backgrounds
- use a simple, solid background
- avoid descriptive text, clip art and fine details
- do not use Garmin branding without permission

The current on-device launcher is not automatically assumed to be the best Store tile. Use the Score Count visual identity, but prepare a Store-specific 500 × 500 asset that follows these constraints.

### Optional on-device Store icon

- 128 × 128 px
- sRGB
- Garmin allows separate full-color and low-color variants for supported Store experiences

### Optional hero image

- 1440 × 720 px
- if text is included, create localized variants

Official brand guidance:
https://developer.garmin.com/brand-guidelines/connect-iq/

## Screenshot set

Use real simulator output from the final release build, not mock controls.

Recommended representative set:

1. **Round MIP / FULL_PHYSICAL** — e.g. Fenix 7 / 260 × 260.
2. **Round AMOLED / TOUCH** — e.g. Venu 2 / 416 × 416.
3. **Rectangular TOUCH** — e.g. Venu Sq 2 / 320 × 360.
4. Optional additional screenshot showing a non-zero score, such as 7–5, to make the purpose obvious.

Keep screenshots visually consistent and do not imply physical-hardware validation where only SDK/simulator validation exists.

## Support

Recommended support URL:

https://github.com/aitorvi1/score-count/issues

Privacy statement:

https://github.com/aitorvi1/score-count/blob/main/garmin/store/PRIVACY.md
