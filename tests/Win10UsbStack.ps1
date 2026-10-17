param([string]$InfPath)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $InfPath) { $InfPath = Join-Path $root 'driver\winstadia.inf' }
$inf = Get-Content -LiteralPath $InfPath -Raw
function Require([bool]$condition, [string]$message) { if (-not $condition) { throw $message } }
function Section([string]$name) {
    if ($inf -notmatch "(?ms)^\[$([regex]::Escape($name))\]\s*(.*?)(?=^\[|\z)") { throw "Missing INF section [$name]" }
    $Matches[1]
}
$usbServices = Section 'InstallUsbWin10.NT.Services'
$usbFilters = Section 'Win10UsbFilters'
$usbWdf = Section 'InstallUsbWin10.NT.Wdf'
Require ($usbServices -match '(?m)^AddService=WUDFRd,0x000001f8,WUDFRD_ServiceInstall\r?$') 'Windows 10 USB must retain WUDFRd as the lower filter.'
Require ($usbServices -match '(?m)^AddService=mshidumdf,0x000001fa,MsHidUmdf_ServiceInstall\r?$') 'Windows 10 USB must associate MsHidUmdf as the HID function driver.'
Require ($usbServices -notmatch '(?m)^AddService=WinUSB,') 'NativeUSB must not register WinUSB as an additional Windows 10 filter.'
Require ($usbServices -notmatch '(?m)^Needs=WINUSB\.NT\.Services\r?$') 'WINUSB.NT.Services associates WinUSB as a conflicting function driver on Windows 10.'
Require ($usbFilters -match '(?m)^HKR,,"LowerFilters",0x00010000,"WUDFRd"\r?$') 'Windows 10 USB must use WUDFRd as the sole lower filter.'
Require ($usbWdf -match '(?m)^UmdfDispatcher=NativeUSB\r?$') 'Windows 10 USB must use NativeUSB with UMDF 2.15+.'
Require ((Section 'UmdfInstall') -match 'UmdfLibraryVersion=2\.25\.0') 'The USB driver must target UMDF 2.25 for Windows 10 compatibility.'
'Win10 USB stack INF checks passed.'
