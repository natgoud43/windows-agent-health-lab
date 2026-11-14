from helpers import read_ini_value

def test_read_ini_value_from_fake_file(tmp_path):
    fake = tmp_path / "config.ini"
    fake.write_text("[policy]\nmode=Prevent\n")
    assert read_ini_value(fake,"policy", "mode") == "Prevent"