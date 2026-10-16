# Shared-axis photo / patent cross-reference layout

This layout supersedes both the photograph-only and patent-only layouts. The reference set is the supplied US D954,832 FIG.3, the Google official controller views, the 1920x1280 product image, and the actual controller photograph downloaded in the preceding work. This is a visually estimated front-view illustration, not a calibrated 3D reconstruction or a measurement of physical millimeters.

## How the references are combined

- Real photographs establish the ordering, paired relationships, relative button sizes and glyph appearance. Their raw coordinates are not copied into the front-view drawing.
- For example, the product image's ABXY half-span is roughly 81 horizontal versus 73.5 vertical pixels; the D-pad is roughly 198 wide versus 178 tall. Both show vertical foreshortening of about 10%. This supports keeping the front-view D-pad square and ABXY equally spaced, not copying these apparent unequal dimensions.
- The patent supplies an approximate undistorted silhouette and an independent size-ratio check. Scan line thickness, dashed details and slight drafting offsets are not treated as exact assembly locations.
- The functional round-button size is 22, between the photographic estimate of 20 and the scan-derived estimate of 24. Pills use 30x18, between 28x15 and 32x20. ABXY remains 36. These are approximate visual compromises, not newly measured physical dimensions.
- One common centerline and horizontal rows enforce symmetry; circles on a neutral stick remain concentric. The body silhouette is unchanged from the preceding orthographic version.

## Central parameters

`LayoutCenterX=277.5`, `ButtonRowY=114`, `StickRowY=190`.

| Group | Shared-axis construction |
|---|---|
| D-pad / ABXY group centers | centerline minus/plus 153, same y=114 |
| ABXY | 36 diameter, four directions at radius 38 |
| Options / Menu | centerline minus/plus 64, y=74, equal 30x18 pills |
| Assistant / Capture | centerline minus/plus 40, y=114, equal 22 diameter |
| Sticks | centerline minus/plus 86, y=190; socket/cap/inner diameters 82/66/44 |
| Stadia | centered at (277.5,190), diameter 40 |
| D-pad | 92x92 single outer contour; all four hit regions use the same transform |

L1/R1 labels remain empty. L2/R2 are not duplicated in the drawing. Dark colors and the white Stadia logo remain unchanged.

## Executable verification

`tests/BalancedLayout.ps1` loads the compiled WPF control, checks paired center/row/size relationships and the D-pad/ABXY shared row, then checks chosen dimensions, concentric stick rings, clickable hit transforms, selection, pressed feedback and motion/reset behavior. Assertions validate the implemented geometry, not physical fidelity.

Reference URLs preserved from the preceding retrieval:

- https://support.google.com/stadia/answer/9565956?hl=en
- https://uncrate.com/google-stadia-gaming-platform/
- https://www.ebay.com/itm/176200617495

ABXY label update: see CENTERED-ABXY.md. Button geometry is unchanged; glyph ink is centered within each button.
