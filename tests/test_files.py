import pytest, os

from helpers import machine_env, read_ini_value

@pytest.mark.parametrize("name, file", [
    ("SENTINEL_HOME", "config.ini"),
    ("GUARD_DATA", r"..\requirements.txt"),
    ("SHIELD_LOGS", r"..\requirements.txt"),
    ("BASTION_HOME", "requirements.txt"),
    ("VAULT_HOME", "README.txt"),
    ("AEGIS_CFG", "requirements.txt")
])
def test_config_file_exists_for_agent(name, file):
    folder = machine_env(name)
    agent_file = os.path.join (folder, file)
    assert os.path.isfile(agent_file)

@pytest.mark.parametrize("section, key, expected", [
    ("service", "name", "SentinelSvc"),
    ("service", "startup", "automatic"),
    ("policy", "mode", "Prevent")
])
def test_sentinel_config_ini(section, key, expected):
    folder = machine_env("SENTINEL_HOME")
    agent_file = os.path.join (folder, "config.ini")
    assert read_ini_value(agent_file, section, key) == expected
   


    