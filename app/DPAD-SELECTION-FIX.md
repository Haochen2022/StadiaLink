# D-pad selection outline correction

The previous control used each closed directional hit region as its selected stroke. Its internal center-to-corner edges therefore appeared as an arrowhead when a direction was clicked.

Closed hit geometry and event routing are unchanged, but those paths never draw a stroke. Four independent open paths follow only the corresponding exterior D-pad curves. Selection highlights the matching exterior path, without closing it through the center. These overlays ignore pointer hits and use the same scale/translation as their hit regions.

Pressed fill, diagonal input, mapping selection, ABXY ink centering, button dimensions, dark theme and hidden L1/R1 labels are preserved. `VerifyMotion` checks the exterior selection edge instead of requiring a closed hit-region stroke.

`tests/DpadSelection.ps1` raises actual WPF mouse events for all four directional shapes and verifies open/unfilled edge geometry, hidden hit-region strokes, no stale highlights, matched transforms and no edge crossing to the center. It also runs the existing layout/glyph/click/pressed-color/motion tests. `tests/RenderDpadSelections.ps1` renders all four selected states directly from the compiled control for visual inspection.
