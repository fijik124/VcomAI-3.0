# VCOM Edited by Fijik

An edited VCOM AI edition for Arma 3 2.22 or newer. Original VCOM by Genesis; this edition is edited by Fijik. CBA and ACE are optional.

The 3.5.0 addon is split into eight signed PBOs:

| PBO | Responsibilities |
| --- | --- |
| `vcm_core.pbo` | Settings, synchronization, contacts and shared lifecycle utilities |
| `vcm_squad.pbo` | Squad FSM, cover, fire and movement, retreat and building entry |
| `vcm_vehicles.pbo` | Vehicle use, transports and infantry/vehicle cooperation |
| `vcm_safety.pbo` | Wall-aware firing and barracks grenade restrictions |
| `vcm_support.pbo` | Cross-owner reinforcement and artillery coordination |
| `vcm_medical.pbo` | Vanilla treatment, ACE deferral and hit reactions |
| `vcm_equipment.pbo` | Rearming, static weapons, mines and charges |
| `vcm_main.pbo` | Complete-mod dependency and automatic startup |

Keep all eight PBOs together. They share runtime functions; individual PBOs are not independently removable plugins. Use feature settings to disable behavior. Splitting the files improves organization and targeted updates, without adding scheduler loops or changing the AI algorithms.

Install `@VCOM_Edited_by_Fijik` on the server, headless clients and player clients. Remove previous VCOM editions, including `@VCOM_AI`, and embedded mission-script copies before loading it. Copy the supplied public key to the server's `keys` directory when signature verification is enabled. Merge the included `REMOTE-EXEC.hpp` into missions with restrictive remote-execution policies.

The legacy `VCM_fnc_*` function names, settings IDs, `userconfig/VCOM_AI` directory and mission-script installation remain compatible. Source functions stay in their existing locations; [tools/addon-project.json](tools/addon-project.json) assigns every function to one PBO. The build copies each function once and rewrites the two internal resource paths to their owning PBOs.

Build and package with Node.js, PowerShell and the `hemtt` command on PATH:

```powershell
node tests/validate.mjs
node tools/build-release.mjs
./tests/run-runtime.ps1 -Addon
./tests/run-runtime.ps1 -Addon -Suite advanced
./tests/run-multiplayer.ps1 -Addon
./tools/package-upload.ps1
```

Version 3.5.0 adds bounded recovery, outdoor grenade checks, smoke cover, queued room entry, anti-tank reservations, multi-squad roles, cross-owner escorts, adaptive planning, casualty evacuation and convoy controls. CBA exposes feature switches and numeric controls. To inspect AI, enable the server's **Enable debugger telemetry and event log** setting, then the player's **Debugger: show local 3D overlay** setting under **VCOM Edited by Fijik**. Both default off.

Output: `build/upload/VCOM_Edited_by_Fijik-3.5.0.zip`. See [FEATURES.md](FEATURES.md) for behaviors and settings, [MIGRATION.md](MIGRATION.md) for verification, and [ROADMAP.md](ROADMAP.md) for remaining acceptance scenarios.
