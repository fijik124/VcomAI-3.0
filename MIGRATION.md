# VCOM Edited by Fijik: Arma 3 2.22 migration

Future behavior requests and remaining acceptance work are tracked in [ROADMAP.md](ROADMAP.md).
The additional behaviors, settings, performance work and addon installation are described in [FEATURES.md](FEATURES.md).

This repository contains VCOM Edited by Fijik as a modular addon and compatible mission scripts. For the mission-script installation, copy `Vcom/` into the mission, include `Vcom/cfgFunctions.hpp` inside `CfgFunctions`, and execute `Vcom/VcomInit.sqf` once from mission `init.sqf`. Merge the supplied `CfgRemoteExec` with the mission's existing configuration. Do not replace other mods' required remote-function declarations.

Version 3.5.0 installs as `@VCOM_Edited_by_Fijik` and contains eight signed PBOs. Remove older VCOM folders before enabling it, including the previous single-PBO `@VCOM_AI` edition. Keep every PBO in the new folder: the main addon declares dependencies on all seven implementation modules. Settings IDs, `VCM_fnc_*` calls and `userconfig/VCOM_AI` remain compatible. Original author credit for Genesis is retained; the launcher and CBA category identify this edition as VCOM Edited by Fijik. See [README.md](README.md) for the module map.

## Changes

- Squad controllers stop when disabled, empty, transferred to another owner, or led by a player. Each run has a distinct token; delayed work checks that token before issuing orders. Event handlers are recorded and removed at shutdown.
- VCOM names its temporary waypoints. Cleanup removes only those waypoints and restores the pre-combat speed mode. Autonomous flanking, transport and forced movement leave authored routes alone.
- Enemy selection returns `objNull` when no hostile contact is known. Maneuvers and artillery use the observer's estimated contact position from `nearTargets`.
- Garrisoning keeps native pathfinding enabled. Soldiers receive distinct positions. Approaches time out and HOLD cancellation releases the behavior.
- Medical actions defer to native treatment and supplies. When ACE Medical is loaded, VCOM does not issue vanilla treatment or force unconsciousness. The legacy ragdoll option now controls a temporary stance reaction only.
- Settings compile locally during preInit. Only whitelisted, typed settings data is synchronized from the server. Arrays are checked recursively; CODE is rejected. JIP clients request a snapshot and receive subsequent updates. Headless-client requests resolve the reply destination from their connected `HeadlessClient_F` object because the engine reports those RPCs with [sender ID zero](https://community.bohemia.net/wiki/remoteExecutedOwner). Replies never target ID zero, which would broadcast them. Regular player requests use the engine-provided sender ID. CBA registration is synchronous and runs once.
- Remote gunfire reports are checked against shooter ownership and rate-limited. Knowledge updates originate on the server and target the machines owning listeners. Laser observations no longer transmit executable code.
- Artillery filters known hostiles, chooses supported HE ammunition separately for each local firing vehicle, checks range and checks for nearby non-hostiles at the proposed impact point.
- Mines use native simulation. Ammo-to-vehicle mine classes are resolved from config and cached. Native mines can also endanger friendly units; VCOM reveals its placed mines to its own side.

## Coordinated fire and movement

Eligible infantry squads now alternate two teams: one holds and supports while the other advances, then they swap. Machine gunners receive first support-team slots. Teams remain in their original engine group. The behavior starts on combat entry and through the existing periodic movement check.

The planner requires at least four available, locally owned rifle-equipped soldiers, with at most eight participants per maneuver. It excludes medics, incapacitated or badly injured soldiers, heavily suppressed soldiers, vehicle occupants, units with disabled pathfinding, and units reserved by another VCOM task. It requires a known infantry contact 60–400 meters away and permits only fire-at-will engagement modes. Authored routes, `VCM_NOFLANK`, garrison orders and reinforcement assignments take priority.

Each team advances at most once per maneuver. Proposed destinations reject water, steep ground and positions within 50 meters of the remembered contact. Native pathfinding still determines whether a route is reachable. If an advance cannot finish within its deadline, the maneuver ends and releases its reservations. The next maneuver has a 45-second cooldown from its start.

Support uses two-second native [`suppressFor`](https://community.bistudio.com/wiki/suppressFor) pulses. Scripted pulses require a clear physical and visible line, and no nearby non-hostile unit in the fire corridor or near the target position. Native AI can still choose its own shots under the mission's engagement rules; these checks cannot guarantee zero friendly fire. The script does not replenish ammunition, change accuracy or widen engagement rules. Movers temporarily own selected targeting and native FSM features and movement behavior, restoring them on role changes and cleanup. See [FEATURES.md](FEATURES.md) for the exact controls.

Turning the feature off, adding a mission waypoint, losing the contact or squad ownership, or losing an eligible participant cancels the maneuver. Cleanup releases temporary watch/movement orders. Per-unit ownership tags let a new VCOM controller release an inherited maneuver when binding its soldiers. The multiplayer regression verifies this release across a real headless-client ownership transfer and verifies controller recovery after that client disconnects.

Available settings are synchronized and exposed in CBA:

```sqf
VCM_FIREMOVEMENT = true;
VCM_COVERSEARCH = true; // Prefer physical cover at team advance destinations.
VCM_BOUNDLENGTH = 10; // Meters per team, clamped to 10–40.
VCM_BOUNDSECONDS = 15; // Seconds per team, clamped to 5–60.
```

With coordinated movement enabled, ineligible squads retain native combat behavior for that movement check. Setting `VCM_FIREMOVEMENT = false` restores the existing uncoordinated `ForceMove` behavior. Disable VCOM movement for a particular group with `(group this) setVariable ["VCM_NOFLANK", true]`.

## Cover selection during advances

Each moving soldier now evaluates eight ground destinations near the proposed advance. The score favors nearby physical obstruction toward the remembered contact and penalizes detours. Three samples at low, crouched and standing body heights use terrain intersections and the object's [`FIRE` geometry](https://community.bohemia.net/wiki/lineIntersectsSurfaces). Only obstructions within 12 meters of the candidate count; soldiers and vehicles do not count as dependable static cover. The search receives a remembered position, not an enemy object or its live location.

Candidates retain the water, slope and 50-meter contact-distance exclusions. They must advance at least four meters toward the contact and remain within the bounded movement distance. Destinations stay at least three meters from support soldiers' positions and other movers' reserved destinations. If every candidate is excluded, the maneuver cancels instead of assigning overlapping destinations. This spacing applies to requested destinations; native pathfinding still controls soldiers' actual paths and stopping positions.

`VCM_COVERSEARCH` is enabled by default, synchronized with the other server settings, and exposed as a CBA checkbox. Turning it off removes the geometry preference while keeping destination spacing and movement exclusions. The search runs once per mover per phase, with no additional continuous scanner. Orders and locality are rechecked after the search before issuing movement.

This feature selects destinations during coordinated advances. It does not force a stance, guarantee protection against penetrating rounds, or prevent every native AI shot through a wall. Wall-aware firing and indoor grenade restrictions are separate requests in [ROADMAP.md](ROADMAP.md).

## Settings

The existing `userconfig/VCOM_AI/AISettingsV3.hpp` remains a server-side option with file patching enabled. Set `VCM_USECBASETTINGS = false` there to use file values instead of registering CBA settings. This is a startup choice; restart the mission after changing it.

The old `VCM_ForceSpeed` CBA setting name remains supported. Runtime code continues to use `VCM_FullSpeed`. CBA sets side-list values directly; those values must be flat arrays such as `[west, east, resistance]`.

For modded artillery magazines, classify ammunition explicitly when its config is insufficient:

```sqf
VCM_ARTYAMMOOVERRIDES = [
    ["MyMod_HE_Magazine", "HE"],
    ["MyMod_Special_Magazine", "IGNORE"]
];
```

Supported classification labels are `HE`, `SMOKE`, `GUIDED`, and `IGNORE`. Automatic fire currently uses HE only. It does not create synthetic laser targets or automatically fire cluster, mine-delivery, or guided ammunition. Smoke classification is available for future fire missions.

Use `group call VCM_fnc_SquadExc` to register a group manually. Do not start the internal FSM directly: the registration function owns its cancellation and cleanup lifecycle.

## Validation

Node.js and HEMTT are needed for static validation:

```powershell
node tests/validate.mjs
```

This stages a temporary addon under `build/validation` and runs `hemtt check` using the command on PATH. It compiles mission SQF plus all embedded FSM clauses and checks controller registration and cancellation transitions. Full diagnostics are in `build/validation.log`. Existing advisory warnings remain. The unregistered `Playground.sqf` scratchpad is excluded; it is not executed by the mission.

Run the native regression mission with an installed Arma 3 dedicated-server executable:

```powershell
./tests/run-runtime.ps1 -ArmaDirectory 'C:/Program Files (x86)/Steam/steamapps/common/Arma 3'
```

The runner binds to `127.0.0.1:2392`, copies a uniquely named test mission into the game's `MPMissions`, starts a hidden server, collects RPT assertions and stops its own process. It removes that temporary mission afterward. Logs remain under `build/runtime`. The game directory must be writable for the temporary mission installation.

Optional CBA/ACE validation uses the same assertions:

```powershell
./tests/run-runtime.ps1 -Mods @('C:/path/to/@CBA_A3', 'C:/path/to/@ace')
```

The native environment is Arma 3 2.22.154126, Windows x64 (the installed executable reports profiling binaries). Optional mod validation uses the installed CBA 3.19.0.260808 and ACE 3.21.2.113.

The expanded native suite checks actual coordinated advances, physical cover selection, infantry and mounted firing safety, real indoor/outdoor grenade throws, inventory conservation, phased retreat, reactive support, building entry, transport unloading and cancellation by new mission orders. Default coordinated advances are 10 meters with a 15-second deadline. Movement assertions require actual travel and both teams completing their phases; no teleporting or simulated locality flags are used. Modular-addon checks also inspect all eight patches, function directories, compiled functions and the squad FSM path. HEMTT compiles 227 SQF files, including 106 extracted FSM clauses and the multiplayer test scripts. The installation emits a startup warning about `a3_characters_f`; it does not prevent the regression missions from completing.

Use `-Addon` to validate the built PBO rather than an embedded mission-script copy. For example, `./tests/run-runtime.ps1 -Addon`. Addon-mode test missions contain no VCOM implementation files. Focused suites are available through `-Suite safety`, `-Suite tactics` and `-Suite vehicle`.

Run the dedicated-server/headless-client regression separately:

```powershell
./tests/run-multiplayer.ps1
./tests/run-multiplayer.ps1 -Mods @('C:/path/to/@CBA_A3', 'C:/path/to/@ace')
```

This runner starts one server and two headless clients using the installed dedicated-server executable. It binds the server to `127.0.0.1:2392` and the clients to distinct loopback addresses, `127.0.0.2` and `127.0.0.3`, so their UDP ports do not collide. It starts each client after the mission is running, then deliberately terminates the first client to check ownership recovery. It stops its own processes and removes its uniquely named temporary mission. Logs remain under `build/multiplayer/run-*`. The game directory must be writable and the loopback ports must be free.

The multiplayer suite covers two headless clients joining in progress, typed settings, live updates, forged-update rejection, and ownership transfers during garrisoning, movement, static deployment, coordinated movement and tactical retreat. It verifies reinforcement and real mortar fire across different HC owners, indoor grenade inventory conservation through handoff, outdoor restoration, and controller recovery after disconnect. It checks that the old owner releases its controller, the new owner runs one controller with a fresh token, inherited reservations clear, pathfinding stays enabled, cancelled deployment preserves its backpack, and authored waypoints survive. Use `./tests/run-multiplayer.ps1 -Addon` to exercise the signed PBO on all three processes.

Run `./tests/run-performance.ps1 -Addon` for matched 128-unit VR combat measurements with VCOM disabled and enabled. The report records mean FPS, 10th-percentile FPS, maximum active SQF scripts and cleanup assertions in `build/performance.csv`. Default measurement time is 60 seconds per variant, following a 15-second warmup. Use `-Seconds 1800` for 30 minutes per variant. This smoke benchmark does not replace campaign or map-specific measurements.

### Modular 3.5.0 verification, November 8, 2026

The build uses the `hemtt` command and produces eight signed PBOs. Static validation compiles 258 SQF files, including 106 extracted FSM clauses, with zero errors and 292 advisory warnings. Release generation compiles 134 SQF files and eight addon configs. The installed native engine is Arma 3 2.22.154126, Stable x64 profiling.

| Scenario | Result | Workspace logs |
| --- | --- | --- |
| Full native regression, vanilla | 170 checks, zero failures | `build/runtime/profiles-20261108-175613` |
| Full native regression, CBA/ACE | 170 checks, zero failures | `build/runtime/profiles-20261108-180914` |
| Expanded features and telemetry, vanilla | 74 checks, zero failures | `build/runtime/profiles-20261108-175205` |
| Expanded features, CBA controls and telemetry, CBA/ACE | 79 checks, zero failures | `build/runtime/profiles-20261108-180725` |
| Focused server/two-HC coordination | 61 checks, zero failures | `build/multiplayer/run-20261108-174729` |
| Full server/two-HC regression, vanilla | 117 checks, zero failures | `build/multiplayer/run-20261108-181245` |
| Full server/two-HC regression, CBA/ACE | 117 checks, zero failures | `build/multiplayer/run-20261108-181657` |
| 128-unit benchmark, VCOM off | 29 checks, zero failures | `build/runtime/profiles-20261108-182041` |
| 128-unit benchmark, VCOM on | 29 checks, zero failures | `build/runtime/profiles-20261108-182213` |

The final 128-unit vanilla benchmark used a 15-second warmup and approximately 61 seconds per variant. VCOM disabled averaged 28.53 server FPS (10th percentile 28.27, maximum five active SQF scripts). Enabled averaged 28.82 FPS (10th percentile 28.52, maximum 48 scripts, 16 group controllers). Both variants passed controller uniqueness, shutdown and native AI-feature restoration checks. Raw results are in `build/performance.csv`. FPS remained similar in this short scenario; the difference does not establish a speedup or predict another mission's performance.

These addon missions load the complete PBO set without embedded VCOM source. New checks cover bounded recovery and reservation cleanup, physical grenade trajectories and real native throw cancellation with conserved ammunition, carried smoke consumption, queued room plans, native anti-tank firing/backblast checks, three distinct squad roles, server-issued cross-owner escort leases, casualty attachment handoff, full evacuation toward improved physical cover, native convoy speed controls, pedestrian halts, CBA registration and bounded debugger data. The new global controls enter the synchronized whitelist; local overlay preferences do not. Debug-off checks verify that event histories stop growing.

Development checks caught and corrected smoke classification/command issues, premature addon CBA registration, and an invalid assumption that a headless client could query another group's owner directly. CBA registration now runs after CBA initializes its settings system, before VCOM starts. Receivers validate server-issued peer leases. The suppression fixture isolates smoke because lingering smoke correctly blocks its visibility check; the separate smoke test still requires a real native projectile and ammunition consumption. The outdoor grenade fixture waits for loaded native ammunition before firing; evacuation waits for actual contact and actor readiness. Successful runs have no SQF expression errors.

The debugger's telemetry, limits and event collection have native coverage. Its graphical Draw3D labels, destination lines and panel still require visual acceptance on a player client. Native `buildingPos` progression does not prove semantic room clearing, and the short convoy checks do not replace a long route test. ACE casualty evacuation remains explicit opt-in and needs mission-specific medical interaction acceptance. No FPS guarantee is made.

### Modular 3.4.1 verification, November 8, 2026

The renamed upload build contains eight signed PBOs. HEMTT compiled all eight addon configs and 107 addon SQF files. Static mission and FSM validation compiled 227 SQF files with zero errors and 174 advisory warnings. The `hemtt` command is used directly by the build tool.

| Scenario | Final result | Workspace logs |
| --- | --- | --- |
| Native, vanilla | 168 checks, zero failures | `build/runtime/profiles-20261108-150805` |
| Native, CBA/ACE | 168 checks, zero failures | `build/runtime/profiles-20261108-144907` |
| Server plus two HCs, vanilla | 93 checks, zero failures | `build/multiplayer/run-20261108-145922` |
| Server plus two HCs, CBA/ACE | 93 checks, zero failures | `build/multiplayer/run-20261108-145228` |

These missions load the complete PBO set with no embedded VCOM source. New checks verify each module's patch, private function directory, compiled public functions, the relocated squad FSM, and startup. Both headless clients report their complete module set. No SQF expression errors occurred in the successful runs. Each PBO and signature is hashed in `BUILD-MANIFEST.json`.

Earlier vanilla runs encountered a bounded advance timeout and a later movement-fixture reset failure. The test reset now restores COMBAT behavior and yields for a native engine update after teleporting its actors; assertions still require actual movement and both completed advances. AI algorithms and their movement deadlines were not changed for the PBO split. Native pathfinding remains subject to the map-specific acceptance checks below.

### Previous single-PBO 3.4.0 verification, November 8, 2026

These historical runs loaded the signed 3.4.0 single-PBO build. Their hashes and benchmark results describe that build. The test missions contain no embedded VCOM source.

| Scenario | Result | Workspace logs |
| --- | --- | --- |
| Native, vanilla | 142 checks, zero failures | `build/runtime/profiles-20261108-123647` |
| Native, CBA/ACE | 142 checks, zero failures | `build/runtime/profiles-20261108-124153` |
| Server plus two HCs, vanilla | 65 checks, zero failures | `build/multiplayer/run-20261108-123329` |
| Server plus two HCs, CBA/ACE | 65 checks, zero failures | `build/multiplayer/run-20261108-123040` |

No SQF expression errors occurred in these runs. The PBO SHA-256 is `e21180b42861c6217a2446bba1eac4b4b936da4333c76130794f26253d1a9b64`. The upload manifest also hashes the signature, public key, settings and documentation. No private signing key is included.

The 128-unit VR benchmark used a 15-second warmup followed by approximately 61 seconds of measurement per variant, with no CBA/ACE loaded:

| VCOM | Mean server FPS | 10th-percentile FPS | Maximum active SQF scripts | Active group controllers |
| --- | ---: | ---: | ---: | ---: |
| Disabled | 28.53 | 28.22 | 5 | 0 |
| Enabled | 28.82 | 28.57 | 36 | 16 |

Both variants passed all three cleanup assertions: no duplicate controllers, no active controllers after shutdown, and restoration of all six recorded native AI features for every unit. There were no SQF expression errors. Logs are in `build/runtime/profiles-20261108-124630` and `build/runtime/profiles-20261108-124800`; historical raw results are in `build/performance-3.4.0.csv`. FPS remained similar in this short scenario. Different tactics change the native simulation workload; longer missions and other maps still need measurement.

## Multiplayer acceptance scenarios

The automated suite covers local headless clients. These broader acceptance checks remain:

1. Join a running mission with a graphical player client on another computer, with CBA enabled and disabled. Check that side arrays, skill arrays and activation state match the server. Change a server setting and verify it reaches the joining client.
2. Repeat ownership handoffs on a networked server with mission-specific rearming, transport and support tasks. The local suite covers garrisoning, movement, static deployment and coordinated movement; it does not exercise every task or network condition.
3. Add and remove soldiers with Zeus; change group leader; take direct player control. Check that handlers do not accumulate and authored waypoints survive.
4. Test vanilla and ACE treatment with wounded soldiers, insufficient supplies, incapacitation and unreachable patients. ACE must retain control of wounds and unconsciousness.
5. Exercise transport seats, turrets and new helicopter variants. The existing transport detector still distinguishes cargo seats; this update does not implement a dedicated aircraft tactical controller.
6. Test artillery with allies and civilians near the target, moving friendlies, translated UI and modded magazines. The friendly check is a snapshot at firing time; it cannot guarantee safety if units move into the impact area afterward.
7. Run a large mission for at least 30 minutes. Compare server frame times, scheduled-script load, stuck units and RPT errors against the previous version with the same scenario.

The server coordinates reinforcement, artillery, squad-role, anti-tank and vehicle/infantry requests across AI owners. Only server-selected fixed data is dispatched; receivers control their own local units. Remote peer owners are taken from server-issued leases because `groupOwner` can report zero for a remote group on a headless client. Include all new behaviors in the remaining player-client and long-mission acceptance scenarios before adopting them for a campaign.
