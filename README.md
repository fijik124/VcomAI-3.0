# VCOM Edited by Fijik

An edited VCOM AI edition for Arma 3 2.22 or newer. Original VCOM by Genesis; this edition is edited by Fijik. **CBA_A3 and ACE, including ACE Medical, are required on the server, headless clients and player clients.**

The 3.8.0 addon is split into eight signed PBOs:

| PBO | Responsibilities |
| --- | --- |
| `vcm_core.pbo` | Settings, synchronization, contacts and shared lifecycle utilities |
| `vcm_squad.pbo` | Squad FSM, cover, fire and movement, retreat and building entry |
| `vcm_vehicles.pbo` | Vehicle use, transports and infantry/vehicle cooperation |
| `vcm_safety.pbo` | Wall-aware firing and barracks grenade restrictions |
| `vcm_support.pbo` | Cross-owner reinforcement and artillery coordination |
| `vcm_medical.pbo` | AI casualty evacuation; ACE Medical owns treatment |
| `vcm_equipment.pbo` | Rearming, static weapons, mines and charges |
| `vcm_main.pbo` | Complete-mod dependency and automatic startup |

Keep all eight PBOs together. They share runtime functions; individual PBOs are not independently removable plugins. Use feature settings to disable behavior. Splitting the files improves organization and targeted updates, without adding scheduler loops or changing the AI algorithms.

Install CBA_A3, ACE and `@VCOM_Edited_by_Fijik` on the server, headless clients and player clients, loading CBA_A3 and ACE first. The addon declares hard dependencies; mission-script startup reports missing dependencies in the RPT and exits. Remove previous VCOM editions, including `@VCOM_AI`, and embedded mission-script copies before loading it. Copy the supplied public key to the server's `keys` directory when signature verification is enabled. Merge the included `REMOTE-EXEC.hpp` into missions with restrictive remote-execution policies.

Configure VCOM through CBA Addon Options. The non-CBA switch, vanilla treatment functions, hit reactions and unused medic scans are removed in 3.7.0. Existing tactical settings and mission-script installation remain supported. Optional `userconfig/VCOM_AI` startup defaults remain available for advanced settings; saved CBA values take priority. Source functions stay in their existing locations; [tools/addon-project.json](tools/addon-project.json) assigns every function to one PBO. The build copies each function once and rewrites the two internal resource paths to their owning PBOs.

Version 3.8.0 adds autonomous counter-flanking, recon observation/reporting, night discipline, defensive positions, doctrine selection and bounded danger memory. AI chooses its own behavior. Eight optional Zeus modules provide specific objectives, fallback/danger overrides and resets; five Eden-only presets support mission authors. Authorized curators see local point/danger markers. See [COMMANDS.md](COMMANDS.md) for automatic decisions, optional overrides, reset controls and limits.

Build and package with Node.js, PowerShell and the `hemtt` command on PATH:

```powershell
node tests/validate.mjs
node tools/build-release.mjs
./tests/run-runtime.ps1 -Addon
./tests/run-runtime.ps1 -Addon -Suite advanced
./tests/run-runtime.ps1 -Addon -Suite doctrine -TimeoutSeconds 480
./tests/run-runtime.ps1 -Addon -Suite cqb
./tests/run-runtime.ps1 -Addon -Suite cqb-floors
./tests/run-multiplayer.ps1 -Addon
./tools/package-upload.ps1
```

Version 3.6.0 adds full mapped room search with geometry sampling, floor and door routes, doorway stacking, observed coverage and partial-search reports. Native indoor movement retains its mission-enabled FSM. The debugger displays chosen actions and reasons, native commands, intended destinations, planned CQB routes, room coverage and live door states. CBA exposes search limits and observation timing alongside existing controls. To inspect AI, enable the server's **Enable debugger telemetry and event log** setting, then the player's **Debugger: show local 3D overlay** setting under **VCOM Edited by Fijik**. Both default off.

Native test runners find the installed Steam Workshop CBA/ACE folders automatically, or accept explicit paths through `-Mods`. The `dependencies` suite deliberately omits automatic mod loading to check failed startup.

Output: `build/upload/VCOM_Edited_by_Fijik-3.8.0.zip`. See [FEATURES.md](FEATURES.md) for behaviors and settings, [MIGRATION.md](MIGRATION.md) for verification, and [ROADMAP.md](ROADMAP.md) for remaining acceptance scenarios.
