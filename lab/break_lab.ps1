<#
  break_lab.ps1 - the incident drill. Injects realistic faults into the lab.
  Run the test suite BEFORE (baseline) and AFTER, then investigate every new red.

  Run in an ELEVATED (admin) PowerShell:
    powershell -ExecutionPolicy Bypass -File .\lab\break_lab.ps1
  Restore with setup_lab.ps1.
#>
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Please run this script in an elevated (Run as administrator) PowerShell.' }

# Policy turned off
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Aegis\Policy' -Name 'BlockScripts' -Value 0
# Wrong case: "prevent" is not "Prevent"
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Bastion' -Name 'Mode' -Value 'prevent'
# Right value, wrong type: text "1" instead of DWORD 1
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\ShieldWatch' -Name 'Enabled'
New-ItemProperty -Path 'HKLM:\SOFTWARE\ShieldWatch' -Name 'Enabled' -Value '1' -PropertyType String | Out-Null
# Weak service account
cmd /c 'sc config AegisSvc obj= "NT AUTHORITY\LocalService" password= ""' | Out-Null
# Unquoted service path with spaces (security risk)
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\BstnSvc' -Name 'ImagePath' -Value 'C:\Bastion Lab\bin\bastion.exe'
# A dependency silently disabled
sc.exe config ShieldCoreSvc start= disabled | Out-Null
# The agent reports a problem.
# Note: events can't be "un-written". After you restore the lab, the event test
# turns green again once this warning is older than its time window (10 minutes).
eventcreate /t WARNING /id 120 /l APPLICATION /so Aegis /d "Aegis: policy BlockScripts is disabled (0). Script-based attacks will NOT be blocked." | Out-Null
# An "evil twin": a user-level variable shadowing a machine one.
# The tests read machine values from the registry, so this should NOT turn anything red.
[Environment]::SetEnvironmentVariable('GUARD_DATA', 'C:\Fake', 'User')

Write-Host 'Something happened overnight... Run the tests in a NEW terminal.'
