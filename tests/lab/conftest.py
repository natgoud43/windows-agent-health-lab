import pytest, os
from tests.helpers import sc, read_reg, machine_env

@pytest.fixture(scope="session", autouse=True)
def lab_ready():
    output=sc("getkeyname", "Bastion Shield")
    if "1060" in output:
        if os.getenv("CI") == "true":
            pytest.fail("Lab not installed in CI: setup_lab.ps1 didn't work as expected")
        else:
            pytest.skip("Lab not installed: run lab\\setup_lab.ps1 in an admin PowerShell")
            

# session: Sentinel's folder can't change during a run, so build the path once
@pytest.fixture(scope="session")
def sentinel_config():
    path = machine_env("SENTINEL_HOME")
    file = os.path.join(path,"config.ini")
    return file
