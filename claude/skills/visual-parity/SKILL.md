---
name: visual-parity
description:
  Capture, measure, and close visual differences between a reference and a candidate interface with
  ImageMagick. Use for visual-parity work on web, desktop, iOS, or Android: screenshot diffs, layout
  and inset regressions, rendering comparisons, and before/after UI validation, regardless of how
  screenshots are acquired.
---

# Visual Parity

Compare reference and candidate screenshots within one platform; do not expect different platforms
(Android and iOS, or Chrome and Safari) to match each other. Screenshot acquisition is outside this
workflow—use any available browser automation, simulator, or device tooling.

## Plan captures

List representative states before changing code. Cover what matters for the interface:

- initial/loading/error/empty/populated states and transient overlays;
- short, long, wrapped, and overflowing content at meaningful scroll positions;
- focus, hover, and keyboard states; theme, orientation, breakpoint, and accessibility-size
  variants.

Capture hard-to-recreate states first. Name pairs systematically, such as `reference-empty.png` and
`candidate-empty.png`, prefixed with the platform or breakpoint when there are several.

## Normalize pairs

Keep device or browser, OS, viewport, orientation, pixel density, theme, locale, font scaling, app
environment, data, navigation, scroll, keyboard, system bars, safe areas, and settled
animation/content identical. Prefer the raw viewport; otherwise crop both images identically. On
mobile, stabilize status and navigation bars, display and font settings, safe areas, and screenshot
scale. In a browser, fix the window size and device scale factor, disable animations and caret
blink, and wait for fonts and images to load. Recapture geometry mismatches; never resize one image
to conceal them.

## Compare with ImageMagick

```bash
# Require identical geometry
reference_geometry="$(magick identify -format '%wx%h' reference.png)"
candidate_geometry="$(magick identify -format '%wx%h' candidate.png)"
[ "$reference_geometry" = "$candidate_geometry" ] || {
  printf 'geometry mismatch: %s vs %s\n' "$reference_geometry" "$candidate_geometry" >&2
  exit 1
}

# Visual evidence
magick reference.png candidate.png -compose difference -composite diff.png
magick reference.png candidate.png -define compose:args=50 -compose blend -composite onion.png
magick -delay 45 -loop 0 reference.png candidate.png blink.gif

# Difference magnitude and fraction of pixels changed beyond a 2% noise threshold
magick compare -metric RMSE reference.png candidate.png null:
magick reference.png candidate.png -compose difference -composite -channel RGB -separate \
  -evaluate-sequence max -threshold 2% -format '%[fx:mean]\n' info:
```

`compare` exits with status 1 when pixels differ; its RMSE remains valid. The ratio ranges from `0`
to `1`. Use metrics to track progress, not as the acceptance criterion. Paired edges indicate
displacement, broad regions indicate fill/color differences, and text halos indicate typography or
rasterization differences. Mask only genuinely nondeterministic pixels, identically in both inputs.

## Iterate

Fix structural differences before details: viewport/safe-area bounds, chrome/overlays, scrolling and
occlusion, keyboard response, typography, then color, radius, icons, and fine spacing. Recapture the
same state after each coherent fix. Verify interactions separately because screenshots cannot prove
behavior. Finish when every planned state is captured and remaining differences are understood and
intentional.
