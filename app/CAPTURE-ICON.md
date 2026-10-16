# Capture icon correction

Only the capture icon's central Ellipse was removed. Its four corner segments, border, diameter, coordinates, click selection, mapping and pressed-color behavior are unchanged. The four Assistant dots remain untouched. Existing D-pad selection, ABXY glyph centering and L2/R2 card shortcuts are preserved.

`tests/CaptureIcon.ps1` inspects the actual compiled WPF control, checks four corner figures and zero center ellipses, confirms Assistant dots and capture bounds, raises a capture click, checks pressed/idle glyph colors and runs motion/reset behavior. An optional output directory renders the actual capture button at enlarged resolution.
