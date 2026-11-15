# VCOM 3.8.0 completed in-game verification

**Done: 10 of 24 checks. Waiting: 14 checks.**

Source: the user's `true` marks in the original in-game checklist, recorded on November 15, 2026. These are user-reported in-game results, separate from the automated native and graphical test counts in [MIGRATION.md](MIGRATION.md). Session date, terrain, mod set, server topology, RPT evidence and numerical benchmark results were not supplied.

Completed checks have been removed from the active [IN_GAME_CHECKLIST.md](IN_GAME_CHECKLIST.md). Their original IDs and `true` statuses are retained here. Remaining checks keep their original IDs and stay `false` until verified.

| ID | Check | Passing result | Done | Notes |
| --- | --- | --- | --- | --- |
| 01 | Addon settings | All 104 controls appear in 18 numbered groups, switches precede value controls, and saved changes survive a mission restart. | true | |
| 02 | Enable debugging | In group 18, enable **Enable AI debugger and telemetry** and **Debugger: show panel and 3D overlay**. Both settings take effect. | true | |
| 03 | Gameplay panel | Near an active AI squad, its group, owner, FPS, task, reason and unit labels appear and update every few seconds. | true | |
| 04 | Squad inspection | Pointing at different squads changes the inspected squad. | true | |
| 05 | Zeus camera | With the camera far from the player's body, the debugger follows nearby squads; selecting another squad changes inspection. | true | |
| 06 | Display switching | Opening and closing Zeus repeatedly preserves readable output without duplicate panels or labels. | true | |
| 17 | Firing safety | Infantry and a direct-fire vehicle gunner hold fire behind a solid blocked lane and resume after it opens. | true | |
| 21 | Vehicles and convoys | Multiple vehicles maintain spacing, halt for pedestrians, dismount appropriately, retain necessary crew and recover from obstacles. | true | |
| 23 | Cancellation and player control | New waypoints or direct control cancel temporary VCOM orders without freezing units or deleting the authored route. | true | |
| 24 | Multiplayer and endurance | Join-in-progress works, HC transfers work when applicable, and a 30-minute battle completes. Compare performance with debugging off and inspect RPT logs for script errors. | true | |

Completion applies to the described checks in the user's tested setup. Additional terrains, equipment, mission integrations and network configurations are not automatically certified. In particular, debugger/HUD coexistence, missing-data messages, disable cleanup, Zeus objective modules and room/door search visuals remain pending where their checklist rows are still `false`.

