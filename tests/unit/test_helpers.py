import pytest, subprocess
from tests.helpers import read_ini_value, count_scm_failures, count_bad_events
from unittest.mock import MagicMock

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


def test_count_scm_failures_converts_output_to_number(monkeypatch):
    envelope = MagicMock(stdout="3\n")
    fake_run = MagicMock(return_value=envelope)
    monkeypatch.setattr(subprocess, "run", fake_run)

    assert count_scm_failures("Aegis Endpoint Guard", 60) == 3 
    fake_run.assert_called_once()

def test_count_scm_failures_raises_on_empty_output(monkeypatch):
    envelope = MagicMock(stdout=" ")
    fake_run = MagicMock(return_value=envelope)
    monkeypatch.setattr(subprocess, "run", fake_run)

    with pytest.raises(ValueError):
        count_scm_failures("Aegis Endpoint Guard", 60)

def test_count_bad_events_converts_output_to_number(monkeypatch):
    envelope = MagicMock(stdout="5\n")
    fake_run = MagicMock(return_value = envelope)
    monkeypatch.setattr(subprocess, "run", fake_run)

    assert count_bad_events("Application", "QAAgent", 10) == 5
    fake_run.assert_called_once()

def test_count_bad_events_raises_on_empty_output(monkeypatch):
    envelope = MagicMock(stdout = " ")
    fake_response = MagicMock(return_value = envelope)
    monkeypatch.setattr(subprocess, "run", fake_response)

    with pytest.raises(ValueError):
        count_bad_events("Application", "QAAgent", 10) 
