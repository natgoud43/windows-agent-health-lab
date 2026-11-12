import pytest, winreg, os

from helpers import read_reg

@pytest.mark.parametrize("agent_name, value_name, expected_value, expected_type",[
    ("QAAgent", "Mode", "Prevent", winreg.REG_SZ),
    ("SentinelLite", "Mode", "Prevent", winreg.REG_SZ),
    ("SentinelLite", "ConfigFile", r"%SENTINEL_HOME%\config.ini", winreg.REG_SZ),
    ("GuardPoint", "DataDir", r"%GUARD_DATA%", winreg.REG_EXPAND_SZ),
    ("ShieldWatch", "Enabled", 1, winreg.REG_DWORD),
    ("ShieldWatch", "LogDir", r"%SHIELD_LOGS%", winreg.REG_EXPAND_SZ),
    ("Bastion", "Mode", "Prevent", winreg.REG_SZ),
    ("Bastion", "HomeDir", r"%BASTION_HOME%", winreg.REG_EXPAND_SZ),
    ("VaultAgent", "Enabled", 1, winreg.REG_DWORD),
    ("VaultAgent", "HomeDir", r"%VAULT_HOME%", winreg.REG_EXPAND_SZ),
    (r"Aegis\Policy", "BlockScripts", 1, winreg.REG_DWORD),
    (r"Aegis\Policy", "Mode", "Prevent", winreg.REG_SZ),
    ("Aegis", "ConfigDir", r"%AEGIS_CFG%", winreg.REG_EXPAND_SZ)
    ])
def test_agents_registry_setting(agent_name, value_name, expected_value, expected_type):
    actual, actual_type = read_reg(winreg.HKEY_LOCAL_MACHINE, rf"SOFTWARE\{agent_name}", value_name)
    assert actual == expected_value
    assert actual_type == expected_type

@pytest.mark.parametrize("value_name, expected_value",[
    ("SENTINEL_HOME", r"C:\SentinelLab"),
    ("GUARD_DATA", r"C:\GuardLab\data"),
    ("SHIELD_LOGS", r"C:\Shield Lab\logs"),
    ("VAULT_HOME", r"C:\Vault Lab"),
    ("BASTION_HOME", r"C:\Bastion Lab"),
    ("AEGIS_CFG", r"C:\AegisLab\config")
    ])
def test_agents_machine_settings_lm_variables(value_name, expected_value):
    actual, _type = read_reg(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment", value_name)
    assert actual == expected_value
    assert os.path.isdir(actual)

def test_qa_agent_current_user_variable():
    log_dir, _type = read_reg(winreg.HKEY_CURRENT_USER, "Environment","AGENT_LOGS")
    profile, _type = read_reg(winreg.HKEY_CURRENT_USER, r"Volatile Environment", "USERPROFILE")
    assert log_dir == os.path.join(profile, "QAAgentLab", "logs")
    assert os.path.isdir(log_dir)