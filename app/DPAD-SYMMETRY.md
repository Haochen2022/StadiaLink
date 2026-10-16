# Four-way D-pad pressed geometry

The previous independent LEFT/RIGHT polygons did not match rotated UP/DOWN.
The corrected hit/fill and exterior-selection geometries share one canonical UP
arm rotated 0/180/270/90 degrees about (110,113).

The existing outer cross, overall 92x92 placement, colors, controls and button
mapping remain unchanged. Concave corner cubics are split exactly at t=.5;
neighboring fills meet along 45-degree seams without positive-area overlap.
Closed hit-region strokes stay transparent. Selection draws only exterior edges.

tests/DpadSymmetry.ps1 loads the compiled WPF control and checks rotational and
mirror symmetry, union with the original outer outline, pairwise intersection
area, mouse hit targets, routed selection, four physical hat directions, four
diagonals and release. It can render a four-direction comparison via -OutDir.

The hidden off-screen HwndSource used by the probe attaches the control to a
presentation source for InputHitTest. It does not send system mouse input.
Near-seam FillContains samples use a .5-unit exclusion for WPF boundary fuzz;
the separate pairwise Geometry.Combine area test still verifies zero overlap.
