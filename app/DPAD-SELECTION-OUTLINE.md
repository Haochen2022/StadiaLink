# Symmetric original D-pad selection outline

Selection again uses the original full U-shaped exterior contour. The canonical
UP contour spans x=92..128 and y=66..99 before the existing 92/94 placement
transform. DOWN, LEFT and RIGHT are rotations about (110,113), so cap lengths,
rounded ends, concave transitions and stroke weight remain symmetric.

Pressed-state fill geometry remains the non-overlapping symmetric version. The
closed hit shapes stay transparent in selection-only state; selection draws no
interior diagonal and applies no fill.

tests/DpadSelectionOutline.ps1 loads the compiled WPF control. It verifies the
four expected unscaled bounds, open paths, rounded caps and joins, exclusive
selection, zero selection fill, opposite/adjacent rotational symmetry and the
existing behavior probe. With -OutDir it renders all four selected states.
