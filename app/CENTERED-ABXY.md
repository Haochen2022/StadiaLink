# ABXY glyph centering

Button coordinates, diameters, spacing and the shared-axis layout are unchanged.

Each ABXY label is built as vector geometry from Segoe UI Semibold at 14 drawing units. Its visible ink bounds are translated to (0,0), and a Path with exactly those bounds is aligned horizontally and vertically in the button. This centers the visible glyph rather than the font's ascent/descent line box. No per-letter guessed offsets are used.

The paths ignore pointer hits; the existing outer button retains its click, tooltip and automation name. Refresh recolors the vector labels using the same idle/pressed brushes as the preceding TextBlock implementation.

Run `powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File tests\CenteredABXY.ps1 -Exe release\StadiaLink.exe` from this source directory. It arranges the actual compiled control, transforms each glyph's visible geometry into its button's coordinate system, and compares both centers. The existing shared-axis, click, pressed-feedback and stick motion/reset checks also run. Geometric centering is exact in drawing coordinates; raster antialiasing varies with display scale.
