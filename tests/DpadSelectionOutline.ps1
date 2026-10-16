param([Parameter(Mandatory=$true)][string]$Exe,[string]$OutDir)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$assembly=[Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($Exe))
$type=$assembly.GetType('StadiaStudio.ControllerVisual',$true)
$visual=[Activator]::CreateInstance($type)
$flags=[Reflection.BindingFlags]'Instance,NonPublic'
$shapes=$type.GetField('sculpted',$flags).GetValue($visual)
$edges=$type.GetField('directionEdges',$flags).GetValue($visual)
$drawing=$type.GetField('drawing',$flags).GetValue($visual)
$accent=$type.GetField('accent',$flags).GetValue($visual)
$checks=0
function Check($ok,[string]$message){if(-not $ok){Write-Output "FAIL: $message";exit 1};$script:checks++}
function Near([double]$a,[double]$b){return [Math]::Abs($a-$b) -lt .000001}
$expected=@{
 13=@(92.0,66.0,36.0,33.0)
 14=@(92.0,127.0,36.0,33.0)
 15=@(63.0,95.0,33.0,36.0)
 16=@(124.0,95.0,33.0,36.0)
}
$hp=[Windows.Interop.HwndSourceParameters]::new('DpadSelectionOutlineProbe',555,395);$hp.WindowStyle=0;$hp.PositionX=-32000;$hp.PositionY=-32000
$source=[Windows.Interop.HwndSource]::new($hp);$source.RootVisual=$visual
$visual.Measure([Windows.Size]::new(555,395));$visual.Arrange([Windows.Rect]::new(0,0,555,395));$visual.UpdateLayout()
$images=@();$ids=@(13,14,15,16)
foreach($id in $ids){
 $edge=$edges[$id];$figures=$edge.Data.GetFlattenedPathGeometry().Figures;$bounds=$edge.Data.Bounds;$target=$expected[$id]
 Check ($figures.Count -eq 1 -and -not $figures[0].IsClosed -and $edge.Fill -eq $null) "Direction $id selection is not one open exterior contour."
 Check ((Near $bounds.X $target[0]) -and (Near $bounds.Y $target[1]) -and (Near $bounds.Width $target[2]) -and (Near $bounds.Height $target[3])) "Direction $id selected outline bounds=$bounds; expected original full U contour $($target -join ',')."
 Check ($edge.StrokeStartLineCap -eq [Windows.Media.PenLineCap]::Round -and $edge.StrokeEndLineCap -eq [Windows.Media.PenLineCap]::Round -and $edge.StrokeLineJoin -eq [Windows.Media.PenLineJoin]::Round) "Direction $id lost rounded outline caps or joins."
 $visual.Select($id)
 foreach($other in $ids){Check (($edges[$other].Stroke -eq $accent) -eq ($other -eq $id)) "Selection $id highlights an incorrect direction $other.";Check ($shapes[$other].Fill -eq [Windows.Media.Brushes]::Transparent) "Selection $id fills direction $other; outline-only state expected."}
 if($OutDir){
  $visual.UpdateLayout();$bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(1110,790,192,192,[Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($drawing)
  $images+=[Windows.Media.Imaging.CroppedBitmap]::new($bitmap,[Windows.Int32Rect]::new(147,127,204,204))
 }
}
# Opposite and adjacent U contours must be identical rotations of the same dimensions.
Check ((Near $edges[13].Data.Bounds.Width $edges[14].Data.Bounds.Width) -and (Near $edges[13].Data.Bounds.Height $edges[14].Data.Bounds.Height)) 'UP/DOWN selected outlines are not symmetric.'
Check ((Near $edges[15].Data.Bounds.Width $edges[16].Data.Bounds.Width) -and (Near $edges[15].Data.Bounds.Height $edges[16].Data.Bounds.Height)) 'LEFT/RIGHT selected outlines are not symmetric.'
Check ((Near $edges[13].Data.Bounds.Width $edges[15].Data.Bounds.Height) -and (Near $edges[13].Data.Bounds.Height $edges[15].Data.Bounds.Width)) 'Horizontal and vertical selected outlines are not 90-degree rotations.'
$type.GetMethod('VerifyMotion').Invoke($visual,@())|Out-Null
if($OutDir){
 New-Item -ItemType Directory -Force -Path $OutDir|Out-Null
 $preview=[Windows.Media.DrawingVisual]::new();$context=$preview.RenderOpen();$context.DrawRectangle([Windows.Media.BrushConverter]::new().ConvertFromString('#222C31'),$null,[Windows.Rect]::new(0,0,864,240))
 for($i=0;$i -lt 4;$i++){
  $context.DrawImage($images[$i],[Windows.Rect]::new($i*216+6,28,204,204))
  $text=[Windows.Media.FormattedText]::new(@('UP','DOWN','LEFT','RIGHT')[$i],[Globalization.CultureInfo]::InvariantCulture,[Windows.FlowDirection]::LeftToRight,[Windows.Media.Typeface]::new('Segoe UI'),14,[Windows.Media.Brushes]::White,1.0)
  $context.DrawText($text,[Windows.Point]::new($i*216+108-$text.Width/2,6))
 }
 $context.Close();$bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(864,240,96,96,[Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($preview)
 $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap));$f=[IO.File]::Create((Join-Path ([IO.Path]::GetFullPath($OutDir)) 'four-selected-outlines.png'));try{$encoder.Save($f)}finally{$f.Dispose()}
}
Write-Output 'PASS: original full U-shaped selected outline restored; four directions are exact rotated counterparts; selection remains outline-only.'
Write-Output "CHECKS=$checks; DIRECTIONS=4; TOP_BOUNDS=92,66,36,33; ROTATIONS=0,180,270,90; FILLS=0."
exit 0
