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
- [assets/score-count-store-icon-500.png](assets/score-count-store-icon-500.png): definitive Store listing icon.

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

The definitive Store listing icon is [assets/score-count-store-icon-500.png](assets/score-count-store-icon-500.png): a 500 × 500 RGB PNG with an embedded sRGB profile and no transparency. It preserves the full square composition of `Logo_garmin.png`, resized with LANCZOS without cropping, added text or design changes. The untagged RGB original was treated as sRGB; its color values were not transformed.

Visual inspection at 500, 128 and 64 px confirms the frontón remains recognizable, the blue/red cards and both zeros remain legible, with no clipping or transparent borders. The outer 10 px contain only the preserved light background. The original image remains unchanged. This asset is exclusively for the Store listing; the on-watch launcher resources are unchanged. Preview sizes are not versioned.

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

Final Store screenshots are native app framebuffers exported with the official simulator's **File > Save Screen Capture** command:

| Screenshot | Device / policy | Native resolution | Score |
| --- | --- | --- | --- |
| [fenix7-7-5.png](assets/screenshots/fenix7-7-5.png) | Fenix 7 / FULL_PHYSICAL | 260 × 260 | 7–5 |
| [venu2-7-5.png](assets/screenshots/venu2-7-5.png) | Venu 2 / TOUCH | 416 × 416 | 7–5 |
| [venusq2-7-5.png](assets/screenshots/venusq2-7-5.png) | Venu Sq 2 / TOUCH | 320 × 360 | 7–5 |
| [venu2-0-0.png](assets/screenshots/venu2-0-0.png) | Venu 2 / TOUCH | 416 × 416 | 0–0 |

The three production releases were rebuilt with official SDK 9.2.0 from source commit `3d9c12f0c43345d81ec8d86141762a53d23034e1`, with zero compiler warnings or errors. No production code, configuration, launcher resources or scores were modified for capture. Fenix 7 was reset with START long, then scored using seven short UP and five short DOWN releases. TOUCH devices were reset by tapping RESET, then scored with seven blue and five red taps. The clean Venu 2 screenshot was captured after tapping RESET.

Each PNG was visually checked: complete blue/red cards, centered digits, full RESET, correct score, no clipping or artifacts. Captures contain only app pixels, without the watch frame, desktop, simulator controls, overlays or cursor. They are not scaled, composited or manually retouched. Temporary scripts, logs and binaries stay ignored under `garmin/bin/`.

These are simulator captures, not physical-hardware validation.

## Support

Recommended support URL:

https://github.com/aitorvi1/score-count/issues

Privacy statement:

https://github.com/aitorvi1/score-count/blob/main/garmin/store/PRIVACY.md
