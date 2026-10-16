param([Parameter(Mandatory=$true)][string]$Exe,[string]$OutDir)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$assembly=[Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($Exe))
$type=$assembly.GetType('StadiaStudio.ControllerVisual',$true)
$visual=[Activator]::CreateInstance($type)
$flags=[Reflection.BindingFlags]'Instance,NonPublic'
$icons=$type.GetField('functionIcons',$flags).GetValue($visual)
$zones=$type.GetField('zones',$flags).GetValue($visual)
$checks=0
function Check($ok,[string]$message){if(-not $ok){Write-Output "FAIL: $message";exit 1};$script:checks++}
$capture=$icons[11]
$dots=@($capture.Children|Where-Object {$_ -is [Windows.Shapes.Ellipse]})
Check ($dots.Count -eq 0) "Capture icon contains $($dots.Count) center dot; expected 0."
Check ($capture.Children.Count -eq 1 -and $capture.Children[0] -is [Windows.Shapes.Path]) 'Capture should contain only the four-corner path.'
$corners=$capture.Children[0]
Check ($corners.Data.GetFlattenedPathGeometry().Figures.Count -eq 4) 'Capture does not have four corner segments.'
Check (@($icons[12].Children|Where-Object {$_ -is [Windows.Shapes.Ellipse]}).Count -eq 4) 'Assistant icon dots were accidentally changed.'
Check ($zones[11].Width -eq 22 -and $zones[11].Height -eq 22 -and [Windows.Controls.Canvas]::GetLeft($zones[11]) -eq 306.5 -and [Windows.Controls.Canvas]::GetTop($zones[11]) -eq 103) 'Capture size/position changed.'
$evt=[Windows.Input.MouseButtonEventArgs]::new([Windows.Input.Mouse]::PrimaryDevice,0,[Windows.Input.MouseButton]::Left);$evt.RoutedEvent=[Windows.UIElement]::MouseLeftButtonDownEvent;$zones[11].RaiseEvent($evt)
Check ($type.GetField('selected',$flags).GetValue($visual) -eq 11) 'Capture click selection regressed.'
$pressed=New-Object bool[] 19;$pressed[11]=$true;$type.GetField('pressed',$flags).SetValue($visual,$pressed);$type.GetMethod('Refresh',$flags).Invoke($visual,@())|Out-Null
$ui=$assembly.GetType('StadiaStudio.Ui')
Check ($corners.Stroke -eq $ui.GetField('Inset').GetValue($null)) 'Pressed corner color regressed.'
$type.GetField('pressed',$flags).SetValue($visual,(New-Object bool[] 19));$type.GetMethod('Refresh',$flags).Invoke($visual,@())|Out-Null
Check ($corners.Stroke -eq $ui.GetField('Text').GetValue($null)) 'Idle corner color did not restore.'
$type.GetMethod('VerifyMotion').Invoke($visual,@())|Out-Null
if($OutDir){
 New-Item -ItemType Directory -Force -Path $OutDir|Out-Null
 $visual.Measure([Windows.Size]::new(555,395));$visual.Arrange([Windows.Rect]::new(0,0,555,395));$visual.UpdateLayout()
 $preview=[Windows.Media.DrawingVisual]::new();$context=$preview.RenderOpen();$context.DrawRectangle([Windows.Media.VisualBrush]::new($zones[11]),$null,[Windows.Rect]::new(0,0,22,22));$context.Close()
 $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(176,176,768,768,[Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($preview)
 $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap));$f=[IO.File]::Create((Join-Path ([IO.Path]::GetFullPath($OutDir)) 'capture.png'));try{$encoder.Save($f)}finally{$f.Dispose()}
}
Write-Output 'PASS: capture has four corners and no center dot; assistant dots, size/position, click and pressed colors preserved.'
Write-Output "CHECKS=$checks; CAPTURE_CORNERS=4; CAPTURE_DOTS=0."
