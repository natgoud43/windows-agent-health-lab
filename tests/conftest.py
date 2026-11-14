import pytest
from helpers import sc

@pytest.fixture(scope="session", autouse=True)
def lab_ready():
    output = sc("getkeyname", "Bastion Shield")
    if "1060" in output:
        pytest.skip("Lab not installed: run lab\\setup_lab.ps1 in an admin PowerShell")