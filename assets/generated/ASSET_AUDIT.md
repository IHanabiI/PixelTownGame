# Asset Audit

Removed from usable assets:
- `*_codex.png` sheets and `codex_crops/`
- opaque dark-background character sprites
- opaque dark-background ramen bowl sprites
- opaque dark-background UI icon sprites
- opaque dark-background prop sprites

Reason:
- These images were generated or cropped as full rectangular presentation images, not transparent game sprites.
- Many had non-transparent pixels on all edges, visible dark backgrounds, or clipped neighboring art.

Current rule:
- Keep full-scene backgrounds in `assets/generated`.
- Keep only verified usable game sprites in `assets/generated/sprites`.
- Regenerate replacements as individual transparent PNGs before wiring them into scripts or data.

Current status:
- `assets/generated/sprites` has been rebuilt with transparent PNG replacements for characters, ramen bowls, UI icons, petals, lanterns, and street props.
- The old `.import` sidecar files for removed bad images were deleted; scripts can load raw PNGs directly when sidecars are absent.
