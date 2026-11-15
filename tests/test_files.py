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
def test_sentinel_config_ini(section, key, expected, sentinel_config):
    assert read_ini_value(sentinel_config, section, key) == expected

@pytest.mark.parametrize("content, section, key, expected", [
    ("[policy]\nmode=Prevent\n","policy", "mode", "Prevent"),
    ("[policy]\nmode = Prevent","policy", "mode", "Prevent"),
    ("[policy]\nMode=Prevent","policy", "mode", "Prevent"),
    ("[policy]\nmode=prevent","policy", "mode", "prevent ")
])
def test_read_ini_value_handles_sloppy_files(content,section, key, expected, tmp_path):
    fake = tmp_path / "config.ini"
    fake.write_text(content)
    assert read_ini_value(fake, section, key) == expected

    