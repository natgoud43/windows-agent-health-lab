import pytest, os

from helpers import sc, binary_path, SERVICES

@pytest.mark.parametrize ("service", SERVICES)
def test_service_auto_start_and_local_system(service):
    output = sc("qc", service)
    assert "AUTO_START" in output
    assert "LocalSystem" in output  


@pytest.mark.parametrize("service", SERVICES)
def test_bin_path_is_quoted_if_has_spaces(service):
    path = binary_path(service)
    assert path is not None
    assert " " not in path or path.startswith('"')

@pytest.mark.parametrize("service", [
    pytest.param("QAAgentSvc", marks=pytest.mark.xfail(reason="QAAgent binary missing - known lab issue")),
    pytest.param("SentinelSvc", marks=pytest.mark.xfail(reason="binPath typo: sentinal.exe vs sentinel.exe")),
    ("BstnSvc"),
    pytest.param("GuardSvc", marks=pytest.mark.xfail(reason="GuardSvc binary missing - known lab issue")),
    pytest.param("ShieldWatchSvc", marks=pytest.mark.xfail(reason="ShieldWatchSvc binary missing - known lab issue")),
    pytest.param("ShieldCoreSvc", marks=pytest.mark.xfail(reason="ShieldCoreSvc binary missing - known lab issue")),
    pytest.param("VltProtSvc", marks=pytest.mark.xfail(reason="VltProtSvc binary missing - known lab issue")),
    pytest.param("AegisSvc", marks=pytest.mark.xfail(reason="AegisSvc binary missing - known lab issue")),
])
def test_service_binary_file_exists(service):
    output = sc("qc", service)
    binary_path = None
    for line in output.splitlines():
        if "BINARY_PATH_NAME" in line:
            binary_path = line.split(":",1)[1].strip().strip('"')
    assert binary_path is not None
    assert os.path.isfile(binary_path)