param([Parameter(Mandatory=$true)][string]$Exe,[string]$OutDir)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$assembly=[Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($Exe))
$type=$assembly.GetType('StadiaStudio.MainWindow',$true)
$window=[Activator]::CreateInstance($type)
$flags=[Reflection.BindingFlags]'Instance,NonPublic'
$checks=0
function Check($ok,[string]$message){if(-not $ok){Write-Output "FAIL: $message";$window.Close();exit 1};$script:checks++}
function Field($name){$type.GetField($name,$flags).GetValue($window)}
function Nodes($root){$root;foreach($child in [Windows.LogicalTreeHelper]::GetChildren($root)){if($child -is [Windows.DependencyObject]){Nodes $child}}}
function Snapshot($name){if(-not $OutDir){return};New-Item -ItemType Directory -Force -Path $OutDir|Out-Null;$root=$window.Content;$root.UpdateLayout();$bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(1340,850,96,96,[Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($root);$encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap));$f=[IO.File]::Create((Join-Path ([IO.Path]::GetFullPath($OutDir)) ($name+'.png')));try{$encoder.Save($f)}finally{$f.Dispose()}}
try{
 $root=$window.Content;$root.Measure([Windows.Size]::new(1340,850));$root.Arrange([Windows.Rect]::new(0,0,1340,850));$root.UpdateLayout()
 # Seed an unsaved mapping edit: clicking a trigger must navigate selection without discarding this draft.
 $draft=Field 'draft';$draft.Map[0]=1;$type.GetField('dirty',$flags).SetValue($window,$true)
 $before=$draft.ToJson();$destinations=$assembly.GetType('StadiaStudio.Destination').GetField('Physical').GetValue($null)
 foreach($id in 17,18){
  $token='TriggerSettings:'+$destinations[$id]
  $card=@(Nodes $root|Where-Object {$_ -is [Windows.Controls.Border] -and $_.Tag -eq $token})
  Check ($card.Count -eq 1) "No clickable $($destinations[$id]) settings card."
  $card=$card[0];Check ($card.Cursor -eq [Windows.Input.Cursors]::Hand -and $card.Focusable) 'Trigger card is not interactive.'
  # Click a nested label so the routed event must bubble through the entire card.
  $label=@(Nodes $card|Where-Object {$_ -is [Windows.Controls.TextBlock] -and $_.Text -eq $destinations[$id]})[0]
  $evt=[Windows.Input.MouseButtonEventArgs]::new([Windows.Input.Mouse]::PrimaryDevice,0,[Windows.Input.MouseButton]::Left);$evt.RoutedEvent=[Windows.Input.Mouse]::MouseDownEvent;$label.RaiseEvent($evt)
  Check ((Field 'selectedButton') -eq $id -and (Field 'sourcePicker').SelectedIndex -eq $id) 'Card click did not select the matching trigger.'
  Check ((Field 'route') -eq 'Mando' -and (Field 'selectedText').Text.StartsWith($destinations[$id])) 'Matching trigger settings did not appear.'
  Check ($before -eq (Field 'draft').ToJson() -and (Field 'dirty')) 'Trigger navigation changed or discarded unsaved edits.'
  Check ($card.BorderBrush.Color.ToString() -eq '#FFCAF57A') 'Selected trigger card did not highlight.'
  $other=(Field 'triggerCards')[35-$id];Check ($other.BorderBrush.Color.ToString() -eq '#FF303B3F') 'Other trigger card retained its selected highlight.'
  Snapshot $destinations[$id]
 }
 # Normal controller selection must clear the trigger-card highlight.
 $type.GetMethod('SelectButton',$flags).Invoke($window,@(0))|Out-Null
 foreach($id in 17,18){Check ((Field 'triggerCards')[$id].BorderBrush.Color.ToString() -eq '#FF303B3F') 'Trigger highlight was not cleared.'}
 # Inject only an in-memory sample; no device I/O or system input is performed.
 $sample=[Activator]::CreateInstance($assembly.GetType('StadiaStudio.PadStatus'));$sample.Raw[8]=128;$sample.Raw[9]=255
 $type.GetField('status',$flags).SetValue($window,$sample)
 foreach($update in (Field 'live')){$update.Invoke($sample)}
 foreach($id in 17,18){$bar=@(Nodes ((Field 'triggerCards')[$id])|Where-Object {$_ -is [Windows.Controls.ProgressBar]})[0];$expected=if($id -eq 17){128}else{255};Check ($bar.Value -eq $expected) 'Live trigger meter regressed.'}
 # Hidden 1x1 input source supplies key-event metadata only; no system keystrokes are sent.
 $keyParams=[Windows.Interop.HwndSourceParameters]::new("TriggerShortcutProbe",1,1);$keyParams.WindowStyle=0;$keyParams.PositionX=-32000;$keyParams.PositionY=-32000
 $keySource=[Windows.Interop.HwndSource]::new($keyParams)
 # Enter and Space should activate the same selection without moving to another page.
 foreach($pair in @(@(17,[Windows.Input.Key]::Return),@(18,[Windows.Input.Key]::Space))){$id=$pair[0];$evt=[Windows.Input.KeyEventArgs]::new([Windows.Input.Keyboard]::PrimaryDevice,$keySource,0,$pair[1]);$evt.RoutedEvent=[Windows.Input.Keyboard]::KeyDownEvent;(Field 'triggerCards')[$id].RaiseEvent($evt);Check ((Field 'selectedButton') -eq $id -and $evt.Handled) 'Keyboard trigger shortcut failed.'}
 Write-Output 'PASS: L2/R2 card clicks select matching settings; highlights, keyboard, live meters and unsaved draft preserved.'
 Write-Output "CHECKS=$checks; L2=17; R2=18; DRAFT_UNCHANGED=True."
}finally{if($keySource){$keySource.Dispose()};$window.Close()}
