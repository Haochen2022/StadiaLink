# L2 / R2 settings shortcuts

Both lower live trigger cards are interactive. Clicking anywhere on the L2 card selects physical input 17; R2 selects input 18. The existing mapping/settings panel on the right updates immediately, without leaving the controller page or discarding pending edits. The selected card receives the accent border. Selecting another controller input clears that border.

Cards retain their existing live progress bars and values. Their cursor, tooltip, focusability and automation names expose the shortcut. Enter and Space use the same selection handler. This operation does not save or apply a profile or write to hardware.

`tests/TriggerSettings.ps1` loads the compiled MainWindow without showing it or starting its device sampling loop. It raises a WPF MouseDown event on a nested L2/R2 label (which synthesizes the normal routed left-button handlers), checks the resulting source picker and mapping panel, highlight changes and preservation of an unsaved draft. It also supplies in-memory trigger values to the live meters and checks Enter/Space event handling. A hidden 1x1 HwndSource supplies key-event metadata only; no mouse/keyboard input is injected into the operating system.
