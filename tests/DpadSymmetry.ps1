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
Add-Type -ReferencedAssemblies @([Windows.Point].Assembly.Location,[Windows.Media.Geometry].Assembly.Location) -TypeDefinition @'
using System;
using System.Windows;
using System.Windows.Media;
public static class DpadSymmetryProbe {
 public static int Verify(Geometry[] arms,Geometry outline) {
  int checks=0; double[] angles={0,180,270,90};
  for(int a=0;a<4;a++)for(int b=a+1;b<4;b++){ double overlap=Geometry.Combine(arms[a],arms[b],GeometryCombineMode.Intersect,null,.0001,ToleranceType.Absolute).GetArea(.0001,ToleranceType.Absolute);if(overlap>.00001)throw new Exception("Directional overlap area="+overlap);checks++; }
  for(double x=62.137;x<158;x+=.73)for(double y=65.271;y<161;y+=.79){
   Point p=new Point(x,y); bool top=arms[0].FillContains(p,.0001,ToleranceType.Absolute);
   for(int i=1;i<4;i++){
    Point q=new RotateTransform(angles[i],110,113).Transform(p);
    bool actual=arms[i].FillContains(q,.0001,ToleranceType.Absolute);
    if(top!=actual)throw new Exception("D-pad "+new[]{13,14,15,16}[i]+" pressed fill is not a rotation of UP at ("+x.ToString("F3")+","+y.ToString("F3")+").");
    checks++;
   }
   if(top!=arms[0].FillContains(new Point(220-x,y),.0001,ToleranceType.Absolute))throw new Exception("UP arm lacks mirror symmetry.");
   int occupied=0;foreach(Geometry arm in arms)if(arm.FillContains(p,.0001,ToleranceType.Absolute))occupied++;
   if((occupied>0)!=outline.FillContains(p,.0001,ToleranceType.Absolute))throw new Exception("Arm union differs from the existing outer contour.");
   if(Math.Abs(Math.Abs(x-110)-Math.Abs(y-113))>.5&&occupied>1)throw new Exception("Directional fills overlap at ("+x.ToString("F3")+","+y.ToString("F3")+"); count="+occupied+".");
   checks+=3;
  }
  return checks;
 }
}
'@
$outlines=@($drawing.Children|Where-Object {$_ -is [Windows.Shapes.Path] -and -not $_.IsHitTestVisible -and $_.Tag -ne 'DpadSelectionEdge'})
try{$checks+=[DpadSymmetryProbe]::Verify([Windows.Media.Geometry[]]@($shapes[13].Data,$shapes[14].Data,$shapes[15].Data,$shapes[16].Data),$outlines[1].Data)}catch{Write-Output ('FAIL: '+$_.Exception.GetBaseException().Message);exit 1}
$hp=[Windows.Interop.HwndSourceParameters]::new("DpadSymmetryProbe",555,395);$hp.WindowStyle=0;$hp.PositionX=-32000;$hp.PositionY=-32000;$source=[Windows.Interop.HwndSource]::new($hp);$source.RootVisual=$visual
$visual.Measure([Windows.Size]::new(555,395));$visual.Arrange([Windows.Rect]::new(0,0,555,395));$visual.UpdateLayout()
$images=@();$angles=@(0,180,270,90);$hats=@(0,4,6,2);$ids=@(13,14,15,16)
for($i=0;$i -lt 4;$i++){
 $id=$ids[$i];$shape=$shapes[$id]
 $point=[Windows.Media.RotateTransform]::new($angles[$i],110,113).Transform([Windows.Point]::new(110,80))
 $point=$shape.RenderTransform.Transform($point)
 $hit=$drawing.InputHitTest($point); Check ([object]::ReferenceEquals($hit,$shape)) "Mouse hit target differs for direction $id, point=$point, hit=$hit, shapeSize=$($shape.ActualWidth)x$($shape.ActualHeight)."
 $event=[Windows.Input.MouseButtonEventArgs]::new([Windows.Input.Mouse]::PrimaryDevice,0,[Windows.Input.MouseButton]::Left);$event.RoutedEvent=[Windows.UIElement]::MouseLeftButtonDownEvent;$shape.RaiseEvent($event)
 Check ($type.GetField('selected',$flags).GetValue($visual) -eq $id) "Selection does not match direction $id."
 $status=[Activator]::CreateInstance($assembly.GetType('StadiaStudio.PadStatus'));$status.HasInput=$true;$status.Raw[1]=$hats[$i];foreach($n in 4..7){$status.Raw[$n]=128}
 $visual.Update($status)
 foreach($other in $ids){Check (($shapes[$other].Fill -eq $accent) -eq ($other -eq $id)) "Pressed fill leaks into direction $other while $id is pressed.";Check (($edges[$other].Stroke -eq $accent) -eq ($other -eq $id)) 'Selection stroke leaks into another direction.'}
 Check ($shape.Stroke -eq [Windows.Media.Brushes]::Transparent) 'Closed hit region draws an internal arrow border.'
 $edge=$edges[$id];Check ($edge.Fill -eq $null -and $edge.Data.GetFlattenedPathGeometry().Figures[0].IsClosed) 'Selection contour is not the requested closed rounded-arm-and-chevron outline.'
 if($OutDir){
  $visual.UpdateLayout()
  $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(1110,790,192,192,[Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($drawing)
  $crop=[Windows.Media.Imaging.CroppedBitmap]::new($bitmap,[Windows.Int32Rect]::new(147,127,204,204));$images+=$crop
 }
 $status.Raw[1]=8;$visual.Update($status)
 foreach($other in $ids){Check ($shapes[$other].Fill -eq [Windows.Media.Brushes]::Transparent) 'Release leaves a pressed direction.'}
}
# Test diagonal physical hats too; two neighboring fills should share a seam, not overlap.
foreach($hat in 1,3,5,7){$status.Raw[1]=$hat;$visual.Update($status);$count=@($ids|Where-Object {$shapes[$_].Fill -eq $accent}).Count;Check ($count -eq 2) "Diagonal hat $hat does not illuminate exactly two arms."}
$visual.Update($null)
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
 $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap));$f=[IO.File]::Create((Join-Path ([IO.Path]::GetFullPath($OutDir)) 'four-directions.png'));try{$encoder.Save($f)}finally{$f.Dispose()}
}
Write-Output 'PASS: four pressed fills are rotationally symmetric; seams match the outer contour; mouse hits, selection, physical hats and release pass.'
Write-Output "CHECKS=$checks; DIRECTIONS=4; SHARED_CENTER=110,113; ROTATIONS=0,180,270,90; OVERLAP=0."
exit 0




