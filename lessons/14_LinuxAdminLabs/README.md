# Section 14. Linux Admin Labs

Real-life Playbooks for everyday Linux administration. They combine everything from the previous sections:
variables and `-e` ([08](../08_Variables/README.md)), facts ([10](../10_Facts/README.md)),
Vault ([11](../11_Vault/README.md)), loops, conditions, handlers and error handling ([12](../12_ControlFlow/README.md))
and templates ([13](../13_Templates/README.md)).

Each lab is a small Ansible project directory with its own `ansible.cfg` and `host_inventory`:
`cd` into it and run the Playbooks from there.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"fontSize": "18px", "lineColor": "#8a8f98", "edgeLabelBackground": "#ffffff", "clusterBkg": "#fafafa", "clusterBorder": "#d0d4da"}, "flowchart": {"wrappingWidth": 480, "curve": "basis", "padding": 14}}}%%
flowchart LR
    CN("<b>Control Node</b><br>cd into a lab directory<br>own ansible.cfg + host_inventory")
    subgraph WEB["Services and web"]
        L01("<b>01 webserver-testing</b><br>-e · assert · template · uri")
        L02("<b>02 services-states</b><br>looped command · include_tasks")
        L03("<b>03 sshd</b><br>systemd in check_mode")
    end
    subgraph CFG["Configuration"]
        L04("<b>04 config-ssh</b><br>lineinfile · validate · handler")
        L09("<b>09 chrony</b><br>template · handler · timezone")
    end
    subgraph DATA["Files, users, data"]
        L05("<b>05 stat</b><br>stat · when on results")
        L06("<b>06 users</b><br>Vault · password_hash")
        L07("<b>07 backup</b><br>fetch · synchronize")
        L08("<b>08 download</b><br>get_url · checksum")
    end
    L10("<b>10 troubleshoot</b><br>find and fix four bugs")
    CN --> WEB
    CN --> CFG
    CN --> DATA
    WEB --> L10
    CFG --> L10
    DATA --> L10
    classDef sand fill:#f3efe7,stroke:#b9b09f,color:#3e3a33
    classDef mint fill:#e2f4ec,stroke:#6db59a,color:#1f5c48
    classDef lilac fill:#edecfc,stroke:#8f89d9,color:#383291
    classDef rose fill:#fbeae6,stroke:#d99b8c,color:#7a2f20
    classDef leaf fill:#e9f4e1,stroke:#8cb975,color:#2e5a1c
    class CN lilac
    class L01,L02,L03,L04,L09,L05,L06,L07,L08 mint
    class L10 rose
```

| Lab | Topics |
|-----|--------|
| [01-webserver-testing](01-webserver-testing/README.md) | `-e` variables, `assert`, `set_fact` + `when`, `template`, `uri` tests |
| [02-services-states](02-services-states/README.md) | Looped `command`, `changed_when` / `failed_when`, looped `include_tasks` |
| [03-sshd](03-sshd/README.md) | Inspect a service with `systemd` in `check_mode` |
| [04-config-ssh](04-config-ssh/README.md) | `vars_prompt`, `lineinfile` with `validate`, handlers, `copy` with `content` |
| [05-stat](05-stat/README.md) | `stat`, `when` on registered results, per-host conditions |
| [06-users](06-users/README.md) | Users from a list, Vault-encrypted passwords, `password_hash`, `authorized_key` |
| [07-backup](07-backup/README.md) | `fetch` vs `ansible.posix.synchronize`, `delegate_to` + `run_once` |
| [08-download](08-download/README.md) | `get_url` with checksum |
| [09-chrony](09-chrony/README.md) | Config from template, handlers, `community.general.timezone` |
| [10-troubleshoot](10-troubleshoot/README.md) | Find and fix four bugs in a broken Playbook |

> [!NOTE]
> The labs change the state of the shared Managed Hosts (`host1`..`host3`): webservers on port 80, the sshd
> configuration, users. Each lab README states what it expects (e.g. which webserver may run on port 80); most labs
> clean up their own preconditions. If the lab gets into a state you cannot repair, recreate the containers with `sudo ./run.sh` in `labenv` on the builder VM
> (this resets everything, see the main [README](../../README.md)).
