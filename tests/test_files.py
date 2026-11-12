import pytest, os

from helpers import machine_env

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
    