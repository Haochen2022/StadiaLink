param([Parameter(Mandatory=$true)][string]$Exe,[Parameter(Mandatory=$true)][string]$OutDir)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$assembly=[Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($Exe))
$type=$assembly.GetType('StadiaStudio.ControllerVisual',$true)
$visual=[Activator]::CreateInstance($type)
$flags=[Reflection.BindingFlags]'Instance,NonPublic'
$drawing=$type.GetField('drawing',$flags).GetValue($visual)
$shapes=$type.GetField('sculpted',$flags).GetValue($visual)
$visual.Measure([Windows.Size]::new(555,395));$visual.Arrange([Windows.Rect]::new(0,0,555,395));$visual.UpdateLayout()
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
foreach($item in @(@(15,'left'),@(16,'right'),@(13,'up'),@(14,'down'))){
 $evt=[Windows.Input.MouseButtonEventArgs]::new([Windows.Input.Mouse]::PrimaryDevice,0,[Windows.Input.MouseButton]::Left);$evt.RoutedEvent=[Windows.UIElement]::MouseLeftButtonDownEvent
 $shapes[$item[0]].RaiseEvent($evt);$visual.UpdateLayout()
 $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(1665,1185,288,288,[Windows.Media.PixelFormats]::Pbgra32)
 $bitmap.Render($drawing)
 $crop=[Windows.Media.Imaging.CroppedBitmap]::new($bitmap,[Windows.Int32Rect]::new(210,180,330,330))
 $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($crop))
 $file=[IO.File]::Create((Join-Path ([IO.Path]::GetFullPath($OutDir)) ($item[1]+'.png')))
 try{$encoder.Save($file)}finally{$file.Dispose()}
}
Write-Output 'PASS: four actual WPF direction selections rendered.'
