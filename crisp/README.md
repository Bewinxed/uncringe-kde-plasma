# crisp — sharp text AND sharp bitmaps at native scale

**The papercut:** at 108 PPI, text looks "like ClearType is off," so you reach for
display scaling (125%). Now text is bigger — and every bitmap on screen is blurry,
because fractional scaling resamples them. Favicons are the tell: Chromium needs a
20px icon at 1.25x, has 16px and 32px cached, picks the nearest (16) and upscales.
Only integer scales land on an exact cached size.

**The insight:** display scaling and font DPI are different levers. Scaling renders
at 96 DPI then resamples everything. Font DPI makes toolkits rasterise glyphs
larger NATIVELY — bigger and sharper, nothing resampled. Scale 1.0 + font DPI 120
reproduces the apparent size of 96 DPI x 1.25 with zero interpolation anywhere.

**Measured, not folklore:**
- "Wayland can't do subpixel AA" is false: Chromium page text measured 82-84%
  colour-fringed (subpixel active) while KDE panel text measured 0.4% (grayscale) —
  same Wayland session. It is a Qt rendering choice, not a Wayland limit.
- The real lever for thin light-on-dark text: `hintfull` + FreeType
  `interpreter-version=35` (snaps stems to the pixel grid, the classic MS look).
  Stem darkening is a no-op for TrueType fonts — FreeType's TT driver doesn't
  implement it.
- Methodology from [wayland-font-dpi](https://github.com/acrion/wayland-font-dpi),
  both halves: GTK propagation via `gsettings text-scaling-factor` (immediate,
  verified not to leak into Chromium's devicePixelRatio), and **auto-computed DPI
  from the panel's EDID physical size** — `crisp apply` measures the primary
  output and derives `font DPI = true_dpi x comfort` (default x1.10). Nothing is
  hardcoded.
- **Measure with `kscreen-doctor -j`, never xdpyinfo**: XWayland *synthesizes*
  its millimetre values to force 96 DPI (`mm = px/96*25.4` exactly), so xdpyinfo
  always "measures" 96 and the whole derivation silently no-ops. This repo fell
  for it once: the panel measured "96.0 DPI" via xdpyinfo and is actually
  109.0 DPI per EDID.

**Gotchas encoded in the script:** `~/.config/fontconfig/fonts.conf` is parsed
AFTER `conf.d/`, so hintstyle must be edited at its source or it silently loses.
`forceFontDPIWayland` applies only at session start.

```
crisp apply          # measure panel -> derive DPI -> scale 1.0 + hintfull +
                     # interpreter 35 + GTK factor. No hardcoded numbers.
crisp apply 1.25     # bigger comfort multiplier over true DPI
crisp dpi 132        # manual override (Qt + GTK together)
crisp status         # panel measurement + what's active
crisp revert         # restores the exact pre-apply scale from saved state
```
