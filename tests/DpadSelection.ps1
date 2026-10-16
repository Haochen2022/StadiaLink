param([Parameter(Mandatory=$true)][string]$Exe)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$assembly=[Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($Exe))
$type=$assembly.GetType('StadiaStudio.ControllerVisual',$true)
$visual=[Activator]::CreateInstance($type)
$flags=[Reflection.BindingFlags]'Instance,NonPublic'
$zones=$type.GetField('zones',$flags).GetValue($visual)
$shapes=$type.GetField('sculpted',$flags).GetValue($visual)
$drawing=$type.GetField('drawing',$flags).GetValue($visual)
$checks=0
function Check($ok,[string]$message){if(-not $ok){Write-Output "FAIL: $message";exit 1};$script:checks++}
function Center($z){return [Windows.Point]::new([Windows.Controls.Canvas]::GetLeft($z)+$z.Width/2,[Windows.Controls.Canvas]::GetTop($z)+$z.Height/2)}
$visual.Measure([Windows.Size]::new(555,395));$visual.Arrange([Windows.Rect]::new(0,0,555,395));$visual.UpdateLayout()
foreach($id in 0,1,2,3){
 $z=$zones[$id];$glyph=$z.Child
 if($glyph -is [Windows.Shapes.Path]){$ink=$glyph.Data.Bounds}
 elseif($glyph -is [Windows.Controls.TextBlock]){
  $face=[Windows.Media.Typeface]::new($glyph.FontFamily,$glyph.FontStyle,$glyph.FontWeight,$glyph.FontStretch)
  $text=[Windows.Media.FormattedText]::new($glyph.Text,[Globalization.CultureInfo]::InvariantCulture,[Windows.FlowDirection]::LeftToRight,$face,$glyph.FontSize,$glyph.Foreground,1.0)
  $ink=$text.BuildGeometry([Windows.Point]::new(0,0)).Bounds
 }else{Check $false 'Unexpected label type.'}
 $ink=$glyph.TransformToAncestor($z).TransformBounds($ink)
 $dx=[Math]::Round($ink.X+$ink.Width/2-$z.ActualWidth/2,6);$dy=[Math]::Round($ink.Y+$ink.Height/2-$z.ActualHeight/2,6)
 Check ([Math]::Abs($dx) -lt .000001 -and [Math]::Abs($dy) -lt .000001) "ABXY label $id ink-center offset=($dx,$dy); expected (0,0)."
}
# Reproduce all four direction selections using the actual mouse routed event.
foreach($id in 15,13,14,16){
 $evt=[Windows.Input.MouseButtonEventArgs]::new([Windows.Input.Mouse]::PrimaryDevice,0,[Windows.Input.MouseButton]::Left);$evt.RoutedEvent=[Windows.UIElement]::MouseLeftButtonDownEvent
 $shapes[$id].RaiseEvent($evt)
 Check ($shapes[$id].Stroke -eq [Windows.Media.Brushes]::Transparent) "D-pad $id outlines its closed hit-region boundary."
 $edges=$type.GetField('directionEdges',$flags).GetValue($visual)
 Check ($edges.Count -eq 4) 'Expected four independent exterior selection edges.'
 $edge=$edges[$id];$figures=$edge.Data.GetFlattenedPathGeometry().Figures
 Check ($edge.Fill -eq $null -and $figures.Count -eq 1 -and $figures[0].IsClosed) "D-pad $id selection edge is not a closed, unfilled rounded-arm-and-chevron contour."
 Check ($edge.Stroke.Color.ToString() -eq '#FFCAF57A') "D-pad $id exterior edge did not highlight."
 foreach($other in 13,14,15,16){if($other -ne $id){Check ($edges[$other].Stroke -eq [Windows.Media.Brushes]::Transparent) 'Stale selection edge remains.'}}
 $clip=$edge.RenderTransform.Transform([Windows.Point]::new(110,113));$hit=$shapes[$id].RenderTransform.Transform([Windows.Point]::new(110,113))
 Check (($clip-$hit).Length -lt .000001) 'Selection edge and hit region have different transforms.'
 if($id -eq 15){Check ([Math]::Abs($edge.Data.Bounds.Right-110) -lt .000001) 'Left contour does not end at the shared center tip.'}
 if($id -eq 16){Check ([Math]::Abs($edge.Data.Bounds.Left-110) -lt .000001) 'Right contour does not end at the shared center tip.'}
 if($id -eq 13){Check ([Math]::Abs($edge.Data.Bounds.Bottom-113) -lt .000001) 'Upper contour does not end at the shared center tip.'}
 if($id -eq 14){Check ([Math]::Abs($edge.Data.Bounds.Top-113) -lt .000001) 'Lower contour does not end at the shared center tip.'}
}
$sockets=@($drawing.Children | Where-Object {$_ -is [Windows.Shapes.Ellipse] -and $_.Fill -ne $null})
Check ($sockets.Count -eq 2) 'Expected two stick sockets.'
for($i=0;$i -lt 2;$i++){$id=8+$i;$socket=Center $sockets[$i];$cap=Center $zones[$id];$dy=$cap.Y-$socket.Y;Check ([Math]::Abs($dy) -lt .000001 -and [Math]::Abs($cap.X-$socket.X) -lt .000001) "stick $id cap offset Y=$dy; expected 0.";Check ($sockets[$i].Width -eq 82 -and $sockets[$i].Height -eq 82) 'Patent socket diameter differs.'}
$inners=@($drawing.Children | Where-Object {$_ -is [Windows.Shapes.Ellipse] -and $_.Fill -eq $null})
Check ($inners.Count -eq 2) 'Expected two concave stick rings.'
for($i=0;$i -lt 2;$i++){$socket=Center $sockets[$i];$inner=Center $inners[$i];Check (($socket-$inner).Length -lt .000001 -and $inners[$i].Width -eq 44 -and $inners[$i].Height -eq 44) 'Inner stick ring is not concentric.'}
Check ($zones[0].Width -eq 36) "ABXY diameter $($zones[0].Width); expected 36."
# Validate relational symmetry before checking absolute target coordinates.
$outlinesForAxis=@($drawing.Children | Where-Object {$_ -is [Windows.Shapes.Path] -and -not $_.IsHitTestVisible -and $_.Tag -ne 'DpadSelectionEdge'})
$dc=$outlinesForAxis[1].RenderTransform.Transform([Windows.Point]::new(110,113))
$xc=Center $zones[2];$bc=Center $zones[1];$fc=[Windows.Point]::new(($xc.X+$bc.X)/2,($xc.Y+$bc.Y)/2)
$rowDelta=$fc.Y-$dc.Y
Check ([Math]::Abs($rowDelta) -lt .000001 -and [Math]::Abs($fc.X+$dc.X-555) -lt .000001) "group-center row delta=$rowDelta; expected 0 with mirrored centers."
foreach($pair in @(@(6,7),@(12,11),@(8,9))){$l=Center $zones[$pair[0]];$r=Center $zones[$pair[1]];Check ([Math]::Abs($l.X+$r.X-555) -lt .000001 -and [Math]::Abs($l.Y-$r.Y) -lt .000001) 'A paired control lost mirror symmetry.';Check ($zones[$pair[0]].Width -eq $zones[$pair[1]].Width -and $zones[$pair[0]].Height -eq $zones[$pair[1]].Height) 'Paired control dimensions differ.'}
foreach($id in 12,11,2,1){$c=Center $zones[$id];Check ([Math]::Abs($c.Y-$dc.Y) -lt .000001) 'Lower function keys and X/B do not share the D-pad row.'}
$expected=@{0=@(430.5,152);1=@(468.5,114);2=@(392.5,114);3=@(430.5,76);6=@(213.5,74);7=@(341.5,74);11=@(317.5,114);12=@(237.5,114);10=@(277.5,190);8=@(191.5,190);9=@(363.5,190)}
foreach($id in $expected.Keys){$c=Center $zones[$id];Check ([Math]::Abs($c.X-$expected[$id][0]) -lt .000001 -and [Math]::Abs($c.Y-$expected[$id][1]) -lt .000001) "Incorrect center for button $id ($c)."}
foreach($id in 0,1,2,3){$c=Center $zones[$id];$d=[Math]::Sqrt([Math]::Pow($c.X-430.5,2)+[Math]::Pow($c.Y-114,2));Check ($zones[$id].Width -eq 36 -and $zones[$id].Height -eq 36 -and $d -eq 38) "ABXY is not an equal-radius 38 diamond."}
foreach($id in 11,12){Check ($zones[$id].Width -eq 22 -and $zones[$id].Height -eq 22) "Incorrect function diameter."}
foreach($id in 6,7){Check ($zones[$id].Width -eq 30 -and $zones[$id].Height -eq 18) "Incorrect pill dimensions.";$icon=$zones[$id].Child;Check ($icon.Height -eq 16) "Pill glyphs are still squeezed."}
Check ($zones[10].Width -eq 40 -and $zones[10].Height -eq 40) 'Incorrect Stadia diameter.'
foreach($id in 8,9){Check ($zones[$id].Width -eq 66 -and $zones[$id].Height -eq 66) 'Incorrect stick cap diameter.'}
$outlines=@($drawing.Children|Where-Object {$_ -is [Windows.Shapes.Path] -and -not $_.IsHitTestVisible -and $_.Tag -ne 'DpadSelectionEdge'})
Check ($outlines.Count -eq 2) 'D-pad inner contour, arrows or center recess remain.'
$body=$outlines[0].Data
$dpad=$outlines[1].Data
$center=$outlines[1].RenderTransform.Transform([Windows.Point]::new(110,113))
Check ([Math]::Abs($center.X-124.5) -lt .000001 -and [Math]::Abs($center.Y-114) -lt .000001) 'Incorrect D-pad center.'
$bounds=$outlines[1].RenderTransform.TransformBounds($dpad.Bounds)
Check ([Math]::Abs($bounds.Width-92) -lt .000001 -and [Math]::Abs($bounds.Height-92) -lt .000001) 'D-pad dimensions differ.'
for($x=7.37;$x -lt 277;$x+=11.5){for($y=23.31;$y -lt 376;$y+=9.7){$l=$body.FillContains([Windows.Point]::new($x,$y));$r=$body.FillContains([Windows.Point]::new(555-$x,$y));Check ($l -eq $r) 'Body silhouette is asymmetric.'}}
for($x=65.37;$x -lt 110;$x+=3.1){for($y=68.31;$y -lt 113;$y+=3.3){$p=$dpad.FillContains([Windows.Point]::new($x,$y));Check ($p -eq $dpad.FillContains([Windows.Point]::new(220-$x,$y))) 'D-pad horizontal symmetry failed.';Check ($p -eq $dpad.FillContains([Windows.Point]::new($x,226-$y))) 'D-pad vertical symmetry failed.'}}
foreach($id in 13,14,15,16){$c=$shapes[$id].RenderTransform.Transform([Windows.Point]::new(110,113));Check ($c -eq $center) 'D-pad hit region is displaced.'}
$labels=$type.GetField('labels',$flags).GetValue($visual)
Check ($labels[4].Text -eq '' -and $labels[5].Text -eq '') 'L1/R1 labels are visible.'
foreach($id in 0,1,2,3,6,7,11,12,10,8,9){
 $evt=[Windows.Input.MouseButtonEventArgs]::new([Windows.Input.Mouse]::PrimaryDevice,0,[Windows.Input.MouseButton]::Left)
 $evt.RoutedEvent=[Windows.UIElement]::MouseLeftButtonDownEvent
 $zones[$id].RaiseEvent($evt)
 Check ($type.GetField('selected',$flags).GetValue($visual) -eq $id) "Click selection failed for $id."
 $pressed=New-Object bool[] 19;$pressed[$id]=$true
 $type.GetField('pressed',$flags).SetValue($visual,$pressed)
 $type.GetMethod('Refresh',$flags).Invoke($visual,@())|Out-Null
 Check ($zones[$id].Background.Color.ToString() -eq '#FFCAF57A') "Pressed feedback failed for $id."
 if($id -lt 4){Check ($zones[$id].Child.Fill -eq $assembly.GetType('StadiaStudio.Ui').GetField('Inset',[Reflection.BindingFlags]'Public,Static').GetValue($null)) 'Pressed label color differs.'}
}
$type.GetField('pressed',$flags).SetValue($visual,(New-Object bool[] 19))
$type.GetMethod('Refresh',$flags).Invoke($visual,@())|Out-Null
# Invoke the application's behavioral tests against its compiled implementation, not source markers.
$type.GetMethod('VerifyMotion').Invoke($visual,@())|Out-Null
Write-Output 'PASS: four D-pad mouse selections use symmetric closed rounded-arm-and-chevron outlines; label/layout/motion regressions preserved.'
Write-Output "CHECKS=$checks; ABXY=36; FUNCTION=22; PILL=30x18; STICK=82/66/44; OFFSET=0; DPAD=92x92; GROUP_ROW_DELTA=0; GLYPH_OFFSET=0,0."
exit 0
