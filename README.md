# Windows Agent Health Lab

A hands-on lab of **seven simulated Windows security agents**, and a **pytest** suite that checks whether each one is configured and running correctly, the way a QA engineer would verify a real endpoint agent.

The lab scripts create the agents (registry settings, environment variables, folders, config files, Windows services and Event Viewer sources). A second script **injects realistic faults**, so the suite can be used as an incident drill: run the tests, see what turns red, investigate, fix, and verify.

## What the suite checks

| Area | File | What it checks |
| --- | --- | --- |
| Services | `tests/test_services.py` | Every agent service starts automatically and runs as LocalSystem; its binary exists; **any service path with spaces is quoted** (unquoted service paths are a known privilege-escalation risk) |
| Registry | `tests/test_registry.py` | Each agent's machine-wide settings have the expected **value and type** (`REG_SZ`, `REG_DWORD`, `REG_EXPAND_SZ`); machine environment variables point to existing folders; the user-level QAAgent variable matches the user's real profile folder |
| Files | `tests/test_files.py` | Each agent's config or requirements file exists where its variable says it should |
| Events | `tests/test_events.py` | Each agent's Event Viewer source exists and has logged **no errors or warnings recently**; Windows (Service Control Manager) logged **no recent start failures** for the agent services |

## The lab agents

| Agent | Service | Settings | Variable |
| --- | --- | --- | --- |
| QAAgent | `QAAgentSvc` | `HKCU\Software\QAAgent`, `HKLM\SOFTWARE\QAAgent` | `AGENT_LOGS` (user) |
| SentinelLite | `SentinelSvc` | `HKLM\SOFTWARE\SentinelLite` | `SENTINEL_HOME` |
| GuardPoint | `GuardSvc` | `HKLM\SOFTWARE\GuardPoint` | `GUARD_DATA` |
| ShieldWatch | `ShieldWatchSvc`, `ShieldCoreSvc` (dependency) | `HKLM\SOFTWARE\ShieldWatch` | `SHIELD_LOGS` |
| Bastion | `BstnSvc` | `HKLM\SOFTWARE\Bastion` | `BASTION_HOME` |
| VaultAgent | `VltProtSvc` | `HKLM\SOFTWARE\VaultAgent` | `VAULT_HOME` |
| Aegis | `AegisSvc` | `HKLM\SOFTWARE\Aegis` (+ `\Policy`) | `AEGIS_CFG` |

## How to run

**Requirements:** Windows 10/11, Python 3, pytest (`pip install pytest`).

1. **Create the lab** in an elevated (Run as administrator) PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\lab\setup_lab.ps1
   ```
2. **Open a new terminal** (so it sees the new environment variables) and run the suite. No admin needed:
   ```
   python -m pytest
   ```
3. **Incident drill:** run `lab\break_lab.ps1` (admin), run the tests again, and investigate every new red. Run `lab\setup_lab.ps1` again to restore the healthy state.
4. **Remove the lab** when you're done: `lab\cleanup_lab.ps1` (admin). Read it first: it deletes the lab's services, registry keys, variables and folders.

## Known issues (by design)

None of the lab agents has a real program behind its service, so the services can't actually run. These checks are marked **`xfail`** with a reason, so they stay visible in every run without hiding new problems. If one of them starts passing, pytest reports **XPASS**, a signal to remove the label.

- Agent binaries are missing (lab limitation)
- `SentinelSvc` points to `sentinal.exe` while the installed file is `sentinel.exe` (a deliberate typo)
- Bastion's binary exists but is a placeholder, not a real program: it **exists**, but that doesn't make it **healthy**

## Design notes

- **The tests only read.** Registry, `sc qc` and Event Viewer queries need no admin rights; only the lab scripts do.
- **Twin-proof.** Machine environment variables are read from the registry, not from the test process's environment, so a user-level variable with the same name (an "evil twin") can't fool the tests. The incident drill includes one to prove it.
- **Recent windows for events.** Event checks look at a recent time window, so old, already-resolved events don't cause permanent false failures.
- **Every check proven both ways.** Each test was run against a broken setup (red) and a healthy one (green), so a pass means something.
- **Shared helpers.** All PowerShell, `sc` and registry access lives in `tests/helpers.py`: each helper translates one question into a Python value, and the tests judge it.

## Project structure

```
windows-agent-health-lab/
├── README.md
├── pytest.ini
├── lab/
│   ├── setup_lab.ps1      # creates the 7 agents (healthy state)
│   ├── break_lab.ps1      # injects faults for the incident drill
│   └── cleanup_lab.ps1    # removes everything
└── tests/
    ├── helpers.py
    ├── test_services.py
    ├── test_registry.py
    ├── test_files.py
    └── test_events.py
```

## About

Built by Natasha Goudesblat, a QA engineer with 12+ years of experience, while learning Python and pytest for Windows endpoint testing.