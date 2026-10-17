$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$source=Get-Content (Join-Path $root 'app\MainWindow.cs') -Raw
function Require([bool]$condition,[string]$message){if(-not $condition){throw $message}}
Require ($source.Contains('DateTime nextDiscovery=DateTime.MinValue,nextPoll=DateTime.MinValue;')) 'Input polling requires a separate throttled UI poll schedule.'
Require ($source.Contains('nextPoll=DateTime.UtcNow.AddMilliseconds(250);Poll();')) 'The UI poll must be limited to four times per second.'
Require ($source.Contains('long due=device==null?-1000000:-80000;')) 'USB status sampling must use the 8 ms cadence.'
Require ($source.Contains('else Thread.Sleep(8);')) 'Waitable-timer fallback must use the 8 ms cadence.'
Require ($source.Contains('Thread.Sleep(device==null?100:8);')) 'No-waitable-timer fallback must use the 8 ms cadence.'
Require ($source.Contains('while(inputSamples.Count>64)')) 'The UI input backlog must stay bounded.'
Require (-not $source.Contains('if(closed||!IsVisible)return;ConsumeInput();frameCount++;')) 'Rendering must not consume input a second time.'
'UI input scheduling checks passed.'
