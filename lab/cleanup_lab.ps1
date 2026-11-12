<#
  cleanup_lab.ps1 - removes EVERYTHING the lab created.
  Please read it before running: it deletes services, registry keys,
  environment variables and folders - but only the lab's own, listed below.

  Run in an ELEVATED (admin) PowerShell:
    powershell -ExecutionPolicy Bypass -File .\lab\cleanup_lab.ps1
#>
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Please run this script in an elevated (Run as administrator) PowerShell.' }

# Services
foreach ($svc in 'QAAgentSvc','SentinelSvc','GuardSvc','ShieldWatchSvc','ShieldCoreSvc','BstnSvc','VltProtSvc','AegisSvc') {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) { sc.exe delete $svc | Out-Null }
}

# Registry keys (lab keys only)
foreach ($key in 'HKLM:\SOFTWARE\QAAgent','HKLM:\SOFTWARE\SentinelLite','HKLM:\SOFTWARE\GuardPoint',
                 'HKLM:\SOFTWARE\ShieldWatch','HKLM:\SOFTWARE\Bastion','HKLM:\SOFTWARE\VaultAgent',
                 'HKLM:\SOFTWARE\Aegis','HKCU:\Software\QAAgent','HKCU:\Software\Bastion','HKCU:\Software\HuntLab') {
    Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
}

# Environment variables (lab variables only)
foreach ($name in 'SENTINEL_HOME','GUARD_DATA','SHIELD_LOGS','BASTION_HOME','VAULT_HOME','AEGIS_CFG') {
    [Environment]::SetEnvironmentVariable($name, $null, 'Machine')
}
foreach ($name in 'AGENT_LOGS','GUARD_DATA','SENTINEL_HOME','VAULT_HOME','SHIELD_LOGS') {
    [Environment]::SetEnvironmentVariable($name, $null, 'User')
}

# Folders (lab folders only)
foreach ($dir in 'C:\QAAgentLab','C:\SentinelLab','C:\GuardLab','C:\Shield Lab','C:\ShieldBin',
                 'C:\Bastion Lab','C:\Vault Lab','C:\VaultBin','C:\AegisLab',
                 (Join-Path $env:USERPROFILE 'QAAgentLab')) {
    Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
}

# Event sources (their past events stay in the log; only the sources are unregistered)
foreach ($src in 'QAAgent','SentinelLite','GuardPoint','ShieldWatch','Bastion','VaultAgent','Aegis') {
    try { if ([System.Diagnostics.EventLog]::SourceExists($src)) { [System.Diagnostics.EventLog]::DeleteEventSource($src) } } catch {}
}

Write-Host 'Lab removed. Open a NEW terminal to see the environment without the lab variables.'
