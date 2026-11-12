<#
  setup_lab.ps1 - creates the Windows Agent Health Lab in its HEALTHY state.
  Seven simulated security agents: registry settings, environment variables,
  folders, config files, Windows services and Event Viewer sources.

  Known lab issues (by design, marked xfail in the tests):
    - No agent has a real binary (the services cannot actually run).
    - SentinelSvc's binary path has a typo: sentinal.exe vs sentinel.exe.

  Run in an ELEVATED (admin) PowerShell:
    powershell -ExecutionPolicy Bypass -File .\lab\setup_lab.ps1
#>
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Please run this script in an elevated (Run as administrator) PowerShell.' }

# ---------- helpers ----------
function Set-RegValue($Path, $Name, $Value, $Type) {
    # Create the key only if it's missing: New-Item -Force on an EXISTING key
    # recreates it empty and deletes every value already in it.
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Set-MachineVar($Name, $Value) {
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Machine')
}

function New-LabService($Name, $BinPath, $DisplayName, $Depends = $null) {
    if (Get-Service -Name $Name -ErrorAction SilentlyContinue) {
        sc.exe config $Name binPath= $BinPath start= auto DisplayName= $DisplayName obj= LocalSystem | Out-Null
    } else {
        sc.exe create $Name binPath= $BinPath start= auto DisplayName= $DisplayName | Out-Null
    }
    if ($LASTEXITCODE -ne 0) { throw "Could not create/configure service $Name" }
    if ($Depends) {
        sc.exe config $Name depend= $Depends | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Could not set dependency for $Name" }
    }
}

function Register-LabEventSource($Source, $Log) {
    # Writes one harmless INFORMATION event, which also registers the source.
    eventcreate /t INFORMATION /id 1 /l $Log /so $Source /d "$Source lab agent installed." | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not register event source $Source" }
}

# ---------- remove any user-level "evil twins" of the lab's machine variables ----------
foreach ($name in 'SENTINEL_HOME','GUARD_DATA','SHIELD_LOGS','BASTION_HOME','VAULT_HOME','AEGIS_CFG') {
    [Environment]::SetEnvironmentVariable($name, $null, 'User')
}

# ---------- QAAgent ----------
Set-RegValue 'HKCU:\Software\QAAgent' 'Version' '2.4.1' 'String'
Set-RegValue 'HKCU:\Software\QAAgent' 'Enabled' 1 'DWord'
Set-RegValue 'HKCU:\Software\QAAgent' 'LogDir' '%AGENT_LOGS%' 'String'
Set-RegValue 'HKLM:\SOFTWARE\QAAgent' 'Mode' 'Prevent' 'String'
Set-RegValue 'HKLM:\SOFTWARE\QAAgent' 'Owner' 'IT Security' 'String'
$qaLogs = Join-Path $env:USERPROFILE 'QAAgentLab\logs'
New-Item -ItemType Directory -Path $qaLogs -Force | Out-Null
[Environment]::SetEnvironmentVariable('AGENT_LOGS', $qaLogs, 'User')
Set-Content -Path (Join-Path $qaLogs 'README.txt') -Value 'Agent service name: QAAgentSvc. If the agent is silent, check the service.'
New-Item -ItemType Directory -Path 'C:\QAAgentLab\bin' -Force | Out-Null
New-LabService 'QAAgentSvc' 'C:\QAAgentLab\bin\qaagent.exe' 'QA Agent Service'
Register-LabEventSource 'QAAgent' 'APPLICATION'

# ---------- SentinelLite ----------
Set-RegValue 'HKLM:\SOFTWARE\SentinelLite' 'ConfigFile' '%SENTINEL_HOME%\config.ini' 'String'
Set-RegValue 'HKLM:\SOFTWARE\SentinelLite' 'Mode' 'Prevent' 'String'
Set-MachineVar 'SENTINEL_HOME' 'C:\SentinelLab'
New-Item -ItemType Directory -Path 'C:\SentinelLab\bin' -Force | Out-Null
Set-Content -Path 'C:\SentinelLab\config.ini' -Value "[service]`r`nname=SentinelSvc`r`nstartup=automatic`r`n[policy]`r`nmode=Prevent"
Set-Content -Path 'C:\SentinelLab\bin\sentinel.exe' -Value 'placeholder'
New-LabService 'SentinelSvc' 'C:\SentinelLab\bin\sentinal.exe' 'Sentinel Lite Service'   # known issue: typo, by design
Register-LabEventSource 'SentinelLite' 'APPLICATION'

# ---------- GuardPoint ----------
Set-RegValue 'HKLM:\SOFTWARE\GuardPoint' 'DataDir' '%GUARD_DATA%' 'ExpandString'
Set-MachineVar 'GUARD_DATA' 'C:\GuardLab\data'
New-Item -ItemType Directory -Path 'C:\GuardLab\data' -Force | Out-Null
Set-Content -Path 'C:\GuardLab\requirements.txt' -Value "GuardPoint requirements`r`n- Machine-wide variable GUARD_DATA = C:\GuardLab\data`r`n- Service GuardSvc must start automatically"
New-LabService 'GuardSvc' 'C:\GuardLab\bin\guard.exe' 'GuardPoint Service'
Register-LabEventSource 'GuardPoint' 'SYSTEM'

# ---------- ShieldWatch ----------
Set-RegValue 'HKLM:\SOFTWARE\ShieldWatch' 'Enabled' 1 'DWord'
Set-RegValue 'HKLM:\SOFTWARE\ShieldWatch' 'LogDir' '%SHIELD_LOGS%' 'ExpandString'
Set-MachineVar 'SHIELD_LOGS' 'C:\Shield Lab\logs'
New-Item -ItemType Directory -Path 'C:\Shield Lab\logs' -Force | Out-Null
Set-Content -Path 'C:\Shield Lab\logs\install.log' -Value "ShieldWatch install complete.`r`nRequirements: see ..\requirements.txt"
Set-Content -Path 'C:\Shield Lab\requirements.txt' -Value "ShieldWatch requirements`r`n- HKLM\SOFTWARE\ShieldWatch: Enabled = 1 (DWORD)`r`n- Service ShieldWatchSvc: automatic`r`n- Service ShieldCoreSvc: automatic (ShieldWatchSvc depends on it)"
New-LabService 'ShieldCoreSvc' 'C:\ShieldBin\core.exe' 'ShieldWatch Core'
New-LabService 'ShieldWatchSvc' 'C:\ShieldBin\watch.exe' 'ShieldWatch Service' 'ShieldCoreSvc'
Register-LabEventSource 'ShieldWatch' 'APPLICATION'

# ---------- Bastion ----------
Set-RegValue 'HKLM:\SOFTWARE\Bastion' 'Mode' 'Prevent' 'String'
Set-RegValue 'HKLM:\SOFTWARE\Bastion' 'HomeDir' '%BASTION_HOME%' 'ExpandString'
Set-RegValue 'HKCU:\Software\Bastion' 'Mode' 'Prevent' 'String'   # decoy in the wrong hive, by design
Set-MachineVar 'BASTION_HOME' 'C:\Bastion Lab'
New-Item -ItemType Directory -Path 'C:\Bastion Lab\bin' -Force | Out-Null
Set-Content -Path 'C:\Bastion Lab\requirements.txt' -Value "Bastion requirements`r`n- Machine-wide setting HKLM\SOFTWARE\Bastion: Mode = Prevent`r`n- Service 'Bastion Shield' must start Automatically"
Set-Content -Path 'C:\Bastion Lab\bin\bastion.exe' -Value 'placeholder'
New-LabService 'BstnSvc' 'C:\Bastion Lab\bin\bastion.exe' 'Bastion Shield'
# Quote the binary path (the path has spaces): set ImagePath directly in the service's registry key.
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\BstnSvc' -Name 'ImagePath' -Value '"C:\Bastion Lab\bin\bastion.exe"'
Register-LabEventSource 'Bastion' 'SYSTEM'

# ---------- VaultAgent ----------
Set-RegValue 'HKLM:\SOFTWARE\VaultAgent' 'Enabled' 1 'DWord'
Set-RegValue 'HKLM:\SOFTWARE\VaultAgent' 'HomeDir' '%VAULT_HOME%' 'ExpandString'
Set-MachineVar 'VAULT_HOME' 'C:\Vault Lab'
New-Item -ItemType Directory -Path 'C:\Vault Lab' -Force | Out-Null
Set-Content -Path 'C:\Vault Lab\README.txt' -Value "VaultAgent requirements`r`n- HKLM\SOFTWARE\VaultAgent: Enabled = 1 (DWORD)`r`n- Service 'Vault Protection Service' must start Automatically"
New-LabService 'VltProtSvc' 'C:\VaultBin\vault.exe' 'Vault Protection Service'
Register-LabEventSource 'VaultAgent' 'APPLICATION'

# ---------- Aegis ----------
Set-RegValue 'HKLM:\SOFTWARE\Aegis' 'ConfigDir' '%AEGIS_CFG%' 'ExpandString'
Set-RegValue 'HKLM:\SOFTWARE\Aegis\Policy' 'BlockScripts' 1 'DWord'
Set-RegValue 'HKLM:\SOFTWARE\Aegis\Policy' 'Mode' 'Prevent' 'String'
Set-MachineVar 'AEGIS_CFG' 'C:\AegisLab\config'
New-Item -ItemType Directory -Path 'C:\AegisLab\config' -Force | Out-Null
Set-Content -Path 'C:\AegisLab\config\requirements.txt' -Value "Aegis requirements`r`n- Service 'Aegis Endpoint Guard' runs as LocalSystem and starts Automatically`r`n- HKLM\SOFTWARE\Aegis\Policy: BlockScripts = 1 (DWORD), Mode = Prevent"
New-LabService 'AegisSvc' 'C:\AegisLab\bin\aegis.exe' 'Aegis Endpoint Guard'
Register-LabEventSource 'Aegis' 'APPLICATION'

Write-Host 'Lab is ready (healthy state). Open a NEW terminal before running the tests.'
