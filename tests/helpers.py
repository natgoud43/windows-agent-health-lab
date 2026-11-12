import os, winreg, subprocess, pytest

SERVICES = ["QAAgentSvc", "SentinelSvc", "GuardSvc", "ShieldWatchSvc", "BstnSvc", "ShieldCoreSvc", "VltProtSvc", "AegisSvc"]

def sc(*args):
    output = subprocess.run(["sc", *args], capture_output= True, text= True).stdout
    return output

def read_reg(hive, path, name):
    with winreg.OpenKey(hive, path) as key:
        value, value_type = winreg.QueryValueEx(key, name)
        return value, value_type

def service_display_name(service):
    output = sc("qc", service)
    name = None
    for line in output.splitlines():
        if "DISPLAY_NAME" in line:
            name = line.split(":",1)[1].strip().strip('"')  
    return name

def binary_path(service):
    output = sc("qc", service)
    path = None
    for line in output.splitlines():
        if "BINARY_PATH_NAME" in line:
            path = line.split(":",1)[1].strip()
    return path      

def source_exists(agent):
    ps = f"[bool](Get-WinEvent -ListProvider '{agent}' -ErrorAction SilentlyContinue)"
    output = subprocess.run(["powershell", "-NoProfile", "-Command", ps], capture_output=True, text=True).stdout
    return output.strip() == "True"

def count_bad_events(log, source, minutes):
    ps = (f"(Get-WinEvent -FilterHashtable @{{LogName='{log}'; ProviderName='{source}'; "
          f"Level=2,3; StartTime=(Get-Date).AddMinutes(-{minutes})}} "
          f"-ErrorAction SilentlyContinue | Measure-Object).Count")
    out = subprocess.run(["powershell", "-NoProfile", "-Command", ps],
                         capture_output=True, text=True).stdout
    return int(out.strip() or 0)

def count_scm_failures(display_name, minutes):
    ps = (f"(Get-WinEvent -FilterHashtable @{{LogName='System'; ProviderName='Service Control Manager'; Id=7000, 7001; " 
          f"StartTime= (Get-Date).AddMinutes(-{minutes})}} -ErrorAction SilentlyContinue | " 
          f"Where-Object {{ $_.Message -like '*{display_name}*' }} | Measure-Object).Count")
    failures = subprocess.run(["powershell", "-NoProfile", "-Command", ps], capture_output=True, text=True).stdout
    return int(failures.strip())

def machine_env(name):
    path, _type = read_reg(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment", name)
    return path
