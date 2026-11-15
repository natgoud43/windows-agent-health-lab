import pytest
from helpers import read_ini_value

def test_read_ini_value_from_fake_file(tmp_path):
    fake = tmp_path / "config.ini"
    fake.write_text("[policy]\nmode=Prevent\n")
    assert read_ini_value(fake,"policy", "mode") == "Prevent"

@pytest.mark.parametrize("content, section, key, expected", [
    ("[policy]\nmode=Prevent\n","policy", "mode", "Prevent"),
    ("[policy]\nmode = Prevent","policy", "mode", "Prevent"),
    ("[policy]\nMode=Prevent","policy", "mode", "Prevent"),
    ("[policy]\nmode=prevent","policy", "mode", "prevent")
])
def test_read_ini_value_handles_sloppy_files(content,section, key, expected, tmp_path):
    fake = tmp_path / "config.ini"
    fake.write_text(content)
    assert read_ini_value(fake, section, key) == expected