import pytest

from helpers import service_display_name, source_exists, count_bad_events, count_scm_failures, SERVICES

@pytest.mark.parametrize("log, source",[
    ("Application", "QAAgent"),
    ("Application", "ShieldWatch"),
    ("Application", "SentinelLite"),
    ("System", "GuardPoint"),
    ("Application", "Aegis"),
    ("System", "Bastion"),
    ("Application", "VaultAgent")
])
def test_event_viewer_no_error_warning_for_agent(log, source):
    assert source_exists(source)
    assert count_bad_events(log, source, 10) == 0


@pytest.mark.parametrize("service", SERVICES)
def test_services_have_no_failure_in_scm(service):
    name = service_display_name(service)
    assert name is not None
    assert count_scm_failures(name, 60) == 0