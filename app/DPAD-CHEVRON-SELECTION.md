# Symmetric closed D-pad selection contours

Each selected direction uses the requested closed contour: the rounded exterior
arm plus two diagonal lines meeting at the D-pad center. The contour is unfilled
until the physical direction is pressed.

One canonical UP geometry is rotated 0/180/270/90 degrees around (110,113) for
UP/DOWN/LEFT/RIGHT. The selection contour and clickable/pressed region use the
same geometry, so all four directions have matching round ends, concave joins,
diagonal lengths and center tips without positive-area overlap.

tests/DpadChevronSelection.ps1 loads the compiled WPF control and verifies four
closed paths, expected bounds, rounded joins, geometry equality with the hit
regions, exclusive selection, no selection fill and four-way rotational symmetry.
