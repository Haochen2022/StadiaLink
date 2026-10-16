param([Parameter(Mandatory=$true)][string]$Exe)
$ErrorActionPreference='Stop'
$registryPath='Software\StadiaStudio'
$originalCulture=[Globalization.CultureInfo]::CurrentUICulture
$keyExisted=$false;$valueExisted=$false;$originalValue=$null;$originalKind=$null
$checks=0;$failure=$null
function Check($ok,[string]$message){if(-not $ok){throw $message};$script:checks++}
try{
 $existing=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($registryPath)
 if($existing){$keyExisted=$true;$valueExisted=$existing.GetValueNames() -contains 'Language';if($valueExisted){$originalValue=$existing.GetValue('Language',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);$originalKind=$existing.GetValueKind('Language')};$existing.Dispose()}
 $key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($registryPath);$key.DeleteValue('Language',$false);$key.Dispose()
 [Globalization.CultureInfo]::CurrentUICulture=[Globalization.CultureInfo]::GetCultureInfo('fr-FR')
 $assembly=[Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($Exe));$type=$assembly.GetType('StadiaStudio.I18n',$true)
 $flags=[Reflection.BindingFlags]'Public,Static'
 $code=$type.GetProperty('Code',$flags).GetValue($null,$null);$saved=$type.GetProperty('Saved',$flags)
 Check ($code -eq 'fr') "startup language code=$code; expected fr from Windows UI culture."
 Check ($saved.GetValue($null,$null) -eq 'fr') 'French Windows UI culture did not map to fr.'
 $cases=[ordered]@{'de-DE'='de';'es-MX'='es';'en-GB'='en';'zh-CN'='zh-CN';'zh-SG'='zh-CN';'ja-JP'='en';'zh-TW'='en';'pt-BR'='en'}
 foreach($pair in $cases.GetEnumerator()){
  [Globalization.CultureInfo]::CurrentUICulture=[Globalization.CultureInfo]::GetCultureInfo($pair.Key)
  $actual=$saved.GetValue($null,$null);Check ($actual -eq $pair.Value) "Windows UI culture $($pair.Key) mapped to $actual; expected $($pair.Value)."
 }
 $key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($registryPath);$key.SetValue('Language','de');$key.Dispose()
 [Globalization.CultureInfo]::CurrentUICulture=[Globalization.CultureInfo]::GetCultureInfo('fr-FR')
 Check ($saved.GetValue($null,$null) -eq 'de') 'Saved user language did not override automatic system matching.'
 $key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($registryPath);$key.SetValue('Language','invalid');$key.Dispose()
 [Globalization.CultureInfo]::CurrentUICulture=[Globalization.CultureInfo]::GetCultureInfo('ja-JP')
 Check ($saved.GetValue($null,$null) -eq 'en') 'Invalid saved language plus unsupported system language did not fall back to English.'
}catch{$failure=$_.Exception.Message}
finally{
 [Globalization.CultureInfo]::CurrentUICulture=$originalCulture
 $key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($registryPath)
 if($valueExisted){$key.SetValue('Language',$originalValue,$originalKind)}else{$key.DeleteValue('Language',$false)}
 $key.Dispose()
 if(-not $keyExisted){try{[Microsoft.Win32.Registry]::CurrentUser.DeleteSubKey($registryPath)}catch{}}
}
if($failure){Write-Output "FAIL: $failure";exit 1}
Write-Output 'PASS: saved language overrides Windows UI culture; first run maps zh-Hans/es/en/fr/de; unsupported or invalid values fall back to English.'
Write-Output "CHECKS=$checks; SYSTEM_CASES=9; SAVED_OVERRIDE=de; FALLBACK=en; REGISTRY_RESTORED=True."
exit 0
