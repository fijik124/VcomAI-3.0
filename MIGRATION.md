# VCOM Edited by Fijik: Arma 3 2.22 migration

Future behavior requests and remaining acceptance work are tracked in [ROADMAP.md](ROADMAP.md).
The additional behaviors, settings, performance work and addon installation are described in [FEATURES.md](FEATURES.md).

## Civilian and surrender additions (November 17, 2026)

Eleven synchronized CBA controls add **19 Civilian Reactions** and **20 Surrender**, bringing the current settings total to 115 across 20 groups. Both behaviors and surrender weapon dropping default to enabled. Existing saved settings keep their values. Civilians do not need to be added to `VCM_SIDEENABLED`. Mission authors can opt units or groups out with `VCM_NOCIVILIAN` and `VCM_NOSURRENDER` respectively.

Missions with restrictive remote-execution policies must merge the updated `VCM_fnc_CivilianDanger` declaration from the supplied `REMOTE-EXEC.hpp`. This receiver accepts only server-originated instructions. Headless-client hearing reports now include their connected HC identity so the server can validate the shooter owner when the engine reports sender zero.

Run `./tests/run-runtime.ps1 -Suite reactions` for civilian travel/freezing, gunfire routing, surrender, inventory conservation, setting changes and ACE restraint checks. Add `-Addon` to exercise the packaged PBOs. The advanced multiplayer suite also checks cross-owner gunfire, forged danger rejection and restoration after transferring panicked civilians or surrendered squads between HCs.

Final automated verification on November 17, 2026:

- HEMTT compiled 305 SQF files with zero compilation errors; the signed release built all eight PBOs. Compiler/style warnings remain recorded in `build/validation.log`.
- Packaged reaction suite: **83 checks, zero failures**, including actual civilian travel, prone freezing, real gunfire, firearm ammunition/attachment conservation, live weapon-drop settings, ACE handcuffing, native surrender fallback and automatic initiation. Log: `build/runtime/profiles-20261117-202122/arma3server_x64_2026-11-17_20-21-22.rpt`.
- Final packaged advanced multiplayer suite: **130 checks, zero failures** with two joining HCs. It covers civilian panic and surrender handoffs, original AI-lock restoration, rejected forged danger instructions, no duplicate ground weapons, plus coordination, evacuation, room-search handoff and recon reporting. Log: `build/multiplayer/run-20261117-202326/server/arma3server_x64_2026-11-17_20-23-26.rpt`.

Reaction snapshots explicitly restore local AI flags, stance and forced speed after the engine resets them during ownership transfer. Completed weapon transfers are recorded publicly and are not repeated from a stale handoff inventory. Surrender initiation runs without scheduler suspension so local controllers and settings changes cannot observe a partially initialized surrender. Shared multiplayer-test enemy groups now remain alive across empty gaps between scenarios and are explicitly deleted afterward.

This repository contains VCOM Edited by Fijik as a modular addon and compatible mission scripts. For the mission-script installation, copy `Vcom/` into the mission, include `Vcom/cfgFunctions.hpp` inside `CfgFunctions`, and execute `Vcom/VcomInit.sqf` once from mission `init.sqf`. Merge the supplied `CfgRemoteExec` with the mission's existing configuration. Do not replace other mods' required remote-function declarations.

Version 3.8.0 installs as `@VCOM_Edited_by_Fijik` and contains eight signed PBOs. **CBA_A3 and ACE including ACE Medical are required on the server, headless clients and player clients.** Load them before VCOM. The core PBO declares `cba_main`, `cba_settings`, `ace_main`, `ace_medical` and `ace_medical_engine` as dependencies. Mission-script startup checks the same patches and logs an error before exiting if any are missing.

Version 3.8.0 adds autonomous tactical roles, recon, counter-flanking, night equipment discipline, defensive posts and bounded danger memory. No Zeus setup is required for those behaviors. Eight optional Zeus point/reset modules support mission-specific objectives and corrections; five Eden-only doctrine presets remain available to mission authors. Resetting a squad returns it to automatic decisions. See [COMMANDS.md](COMMANDS.md) for controls, server API and practical limits. Missions with restrictive remote-execution policies must merge the updated declarations for `VCM_fnc_CommanderRequest` and `VCM_fnc_ReconReport`.

Remove older VCOM folders before enabling it, including the previous single-PBO `@VCOM_AI` edition. Keep every PBO in the new folder: the main addon declares dependencies on all seven implementation modules. Original author credit for Genesis is retained; the launcher and CBA category identify this edition as VCOM Edited by Fijik. See [README.md](README.md) for the module map.

The optional-CBA detection and `VCM_USECBASETTINGS` switch are removed. CBA settings always register. ACE owns medical treatment and hit reactions: `VCM_fnc_HealSelf`, `VCM_fnc_MedicHeal`, `VCM_fnc_MedicalHandler`, `VCM_fnc_AIHIT`, `VCM_fnc_RMedics`, `VCM_fnc_KitChk`, `VCM_RAGDOLL` and `VCM_RAGDOLLCHC` have been removed. Missions that call these functions must remove those calls. No replacement vanilla treatment is provided.

Casualty evacuation now has one opt-in, `VCM_CASEVAC`, defaulting to false. The redundant `VCM_ACECASEVAC` setting is removed. Review saved CBA settings on upgrade: a previously saved `VCM_CASEVAC=true` enables evacuation without the former second gate. To keep evacuation disabled, save `VCM_CASEVAC=false`; to retain previously enabled evacuation, save true.

## Changes

- Squad controllers stop when disabled, empty, transferred to another owner, or led by a player. Each run has a distinct token; delayed work checks that token before issuing orders. Event handlers are recorded and removed at shutdown.
- VCOM names its temporary waypoints. Cleanup removes only those waypoints and restores the pre-combat speed mode. Autonomous flanking, transport and forced movement leave authored routes alone.
- Enemy selection returns `objNull` when no hostile contact is known. Maneuvers and artillery use the observer's estimated contact position from `nearTargets`.
- Garrisoning keeps native pathfinding enabled. Soldiers receive distinct positions. Approaches time out and HOLD cancellation releases the behavior.
- ACE Medical owns treatment and unconsciousness. VCOM only supplies optional casualty evacuation, preserving medical state and supplies.
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

The existing `userconfig/VCOM_AI/AISettingsV3.hpp` remains a server-side source of startup defaults with file patching enabled, including advanced skill/config arrays. CBA settings always register and saved CBA values take priority. Restart the mission after changing startup defaults. The old CBA bypass switch has no effect and should be removed from custom files.

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

### User-reported in-game acceptance

**10 of 24 manual checks are done (`true`)**: addon settings (01), debugger activation/gameplay panel/squad inspection/Zeus camera/display transitions (02–06), firing safety (17), vehicles/convoys (21), cancellation/player control (23), and multiplayer/endurance (24). These results come from the user's edited checklist; they do not add to the automated assertion counts below. Session metadata, machine topology, logs and numerical performance measurements were not supplied.

The completed rows are archived in [TEST_RESULTS.md](TEST_RESULTS.md) and removed from the active [IN_GAME_CHECKLIST.md](IN_GAME_CHECKLIST.md). The remaining 14 rows keep their original IDs and `false` values. Other HUD compatibility, missing-data/disable behavior, tactical maneuvers, Zeus objective modules, building/locked-room handling, grenades, smoke/anti-tank, night equipment and ACE evacuation still await manual completion.

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

Normal native runners automatically load the installed Steam Workshop CBA/ACE folders. For another installation, supply both required mod paths:

```powershell
./tests/run-runtime.ps1 -Mods @('C:/path/to/@CBA_A3', 'C:/path/to/@ace')
```

The current native environment is Arma 3 2.22.154191, Windows x64 (the installed executable reports profiling binaries), with CBA 3.19.0.260808 and ACE 3.21.2.113. Historical November 8 results below used 2.22.154126.

The expanded native suite checks actual coordinated advances, physical cover selection, infantry and mounted firing safety, real indoor/outdoor grenade throws, inventory conservation, phased retreat, reactive support, building entry, transport unloading and cancellation by new mission orders. Default coordinated advances are 10 meters with a 15-second deadline. Movement assertions require actual travel and both teams completing their phases; no teleporting or simulated locality flags are used. Modular-addon checks also inspect all eight patches, their required dependencies, function directories, compiled functions and the squad FSM path. HEMTT compiles 294 SQF files, including 106 extracted FSM clauses and the multiplayer test scripts. The installation emits a startup warning about `a3_characters_f`; it does not prevent the regression missions from completing.

Use `-Addon` to validate the built PBO rather than an embedded mission-script copy. For example, `./tests/run-runtime.ps1 -Addon`. Addon-mode test missions contain no VCOM implementation files. Focused suites are available through `-Suite safety`, `-Suite tactics` and `-Suite vehicle`.

Missing-dependency acceptance runs in mission-script mode and deliberately skips automatic mod loading:

```powershell
./tests/run-runtime.ps1 -Suite dependencies
./tests/run-runtime.ps1 -Suite dependencies -Mods @('C:/path/to/@CBA_A3')
```

Each negative test requires absent dependencies, rejected initialization, a completed startup script and no partially initialized AI runtime. The addon dependency declarations are inspected by normal addon tests.

Run the dedicated-server/headless-client regression separately:

```powershell
./tests/run-multiplayer.ps1
./tests/run-multiplayer.ps1 -Mods @('C:/path/to/@CBA_A3', 'C:/path/to/@ace')
```

This runner starts one server and two headless clients using the installed dedicated-server executable. It binds the server to `127.0.0.1:2392` and the clients to distinct loopback addresses, `127.0.0.2` and `127.0.0.3`, so their UDP ports do not collide. It starts each client after the mission is running, then deliberately terminates the first client to check ownership recovery. It stops its own processes and removes its uniquely named temporary mission. Logs remain under `build/multiplayer/run-*`. The game directory must be writable and the loopback ports must be free.

The multiplayer suite covers two headless clients joining in progress, typed settings, live updates, forged-update rejection, and ownership transfers during garrisoning, movement, static deployment, coordinated movement and tactical retreat. It verifies reinforcement and real mortar fire across different HC owners, indoor grenade inventory conservation through handoff, outdoor restoration, and controller recovery after disconnect. It checks that the old owner releases its controller, the new owner runs one controller with a fresh token, inherited reservations clear, pathfinding stays enabled, cancelled deployment preserves its backpack, and authored waypoints survive. Use `./tests/run-multiplayer.ps1 -Addon` to exercise the signed PBO on all three processes.

Run `./tests/run-performance.ps1 -Addon` for matched 128-unit VR combat measurements with VCOM disabled and enabled. Both variants load required CBA/ACE. The report records mean FPS, 10th-percentile FPS, maximum active SQF scripts and cleanup assertions in `build/performance.csv`. Default measurement time is 60 seconds per variant, following a 15-second warmup. Use `-Seconds 1800` for 30 minutes per variant. This smoke benchmark does not replace campaign or map-specific measurements.

### Tactical doctrine verification in 3.8.0, November 14–15, 2026

Static validation compiles 292 SQF files, including 106 extracted FSM clauses, with zero errors and 395 advisory warnings. Release generation compiles 161 SQF files and eight addon configs. All 158 staged implementation functions, startup, defaults, the squad FSM and module definitions match the current source. All eight signed PBOs match the release output and pass signature verification against the supplied `vcm_3.8.0.bikey` public key. Native checks use the required CBA/ACE stack and engine versions listed above.

| Scenario | Result | Workspace logs |
| --- | --- | --- |
| Autonomous doctrine, native movement, recon, defense, fallback and carried night equipment | 97 checks, zero failures | `build/runtime/profiles-20261115-145358` |
| Full signed-addon regression with CBA/ACE | 193 checks, zero failures | `build/runtime/profiles-20261115-145535` |
| Full server/two-HC regression after request-permission correction | 165 checks, zero failures | `build/multiplayer/run-20261115-145008` |

These 455 passing checks use the same signed PBO set before the CBA menu update described below. The doctrine suite requires AI-selected recon and defense without Zeus setup, native travel to assigned positions, cancellation by authored routes, remembered-contact reports, return-fire policy cleanup, real equipped flashlight/IR-laser behavior and a native hand-flare projectile consuming carried ammunition. Earlier development runs exposed movement and night-equipment fixture failures. Multiplayer validation also caught two request gates that incorrectly relied on `isRemoteExecuted`, which is false for native HC-origin traffic with sender zero. Remote commander requests now require an authenticated curator, while server scripts use the non-whitelisted `VCM_fnc_CommanderOrder`. Remote reports validate their source owner independently of that flag; server-local distribution uses the non-whitelisted `VCM_fnc_ReconPublish`. Null identities cannot select the trusted server path. The later user-reported debugger inspection/Zeus camera, multiplayer and endurance cases are now complete as recorded in TEST_RESULTS.md. Zeus objective modules/markers, more building models, other HUD compatibility, medical interactions and the other unchecked cases remain waiting.

### Grouped CBA settings in 3.8.0, November 15, 2026

All 104 Addon Options settings now use 18 numbered, collapsible subcategories under the existing VCOM entry. The master activation switch comes first; each group places switches before value controls and sorts each set alphabetically. Setting IDs, defaults, limits, local/global scope and the legacy full-speed callback are retained. Only `vcm_core.pbo` changes; the other seven PBO hashes match the tactical acceptance build above. Static compilation still reports zero errors and 395 advisory warnings.

The rebuilt signed addon passes the existing expanded suite: 107 checks, zero failures, in `build/runtime/profiles-20261115-153332`. This includes CBA registration, settings types/defaults, synchronized snapshots, grenade safeguards, convoy controls, coordination and physical casualty evacuation. Earlier grouped-menu runs intermittently returned no cover plan in the casualty fixture; the previous core passed the same suite, and the final grouped core passed with extra diagnostic logging. No evacuation implementation or fixture assertions changed. The passing run still requires real casualty travel, improved cover and attachment cleanup. The user subsequently marked the grouped-menu layout and persistence check 01 as done; see TEST_RESULTS.md.

### Debugger visibility in 3.8.0, November 15, 2026

The debugger panel now uses a VCOM-owned structured-text control on the active gameplay or Zeus display. Mission hints cannot overwrite it. Unit filtering follows the actual camera, including scripted and curator cameras, and Zeus selection can choose the inspected squad. Opening or closing Zeus recreates the control on the correct display. Waiting server settings and absent fresh telemetry produce visible status messages.

The local `VCM_DEBUGOVERLAY` default is now true, while the server/mission `VCM_Debug` default remains false. Enabling **Enable AI debugger and telemetry** therefore shows the panel and labels with fresh defaults; existing saved local false values must be changed explicitly through **Debugger: show panel and 3D overlay** in **18 Debugger and Telemetry**. Disabling either switch removes the panel, cached drawing data and Draw3D handler. Local UI maintenance starts before the client waits for the server settings snapshot, and CBA switch callbacks refresh the view immediately. Replace the addon on server and clients and restart Arma after installing it.

Static validation compiles 294 SQF files with zero errors and 401 advisory warnings; release generation compiles 162 SQF files and eight configs. All 159 staged implementation functions match the source. The final signed build passes all 193 native regression checks in `build/runtime/profiles-20261115-162248` and all 14 graphical debugger checks in `build/debug/run-20261115-162933`. The graphical run uses a real player display, a scripted camera over 1,000 meters from the player, four live AI labels, a native Zeus interface, display transitions and full disable cleanup. The panel is confirmed shown with readable text and nonzero dimensions on both displays; final subjective appearance with other mod HUDs remains mission-specific.

Run `./tests/run-debug.ps1 -Visible` for the isolated graphical acceptance mission. It uses the required CBA/ACE stack and the built addon, tests gameplay and Zeus display controls, camera-relative squad selection and disable cleanup, and stops only its own client process. Its generated profile and logs stay under `build/debug`; existing game sessions are left running.

### Required-stack verification in 3.7.0, November 14, 2026

Static validation compiles 267 SQF files, including 106 extracted FSM clauses, with zero errors and 308 advisory warnings. Release generation compiles 139 SQF files and eight addon configs, producing eight signed PBOs. Native checks use Arma 3 2.22.154191, CBA 3.19.0.260808 and ACE 3.21.2.113 unless dependencies are deliberately omitted.

| Scenario | Result | Workspace logs |
| --- | --- | --- |
| Mission-script startup with no CBA/ACE | 6 checks, zero failures | `build/runtime/profiles-20261114-190032` |
| Mission-script startup with CBA only | 6 checks, zero failures | `build/runtime/profiles-20261114-190214` |
| Full signed-addon regression with CBA/ACE | 180 checks, zero failures | `build/runtime/profiles-20261114-190424` |
| Expanded features, CBA controls and evacuation with CBA/ACE | 94 checks, zero failures | `build/runtime/profiles-20261114-190747` |
| Full server/two-HC regression with CBA/ACE | 133 checks, zero failures | `build/multiplayer/run-20261114-190914` |

The normal addon assertions verify every required patch is loaded and explicitly listed by the core PBO. The negative fixtures verify startup exits without creating partial runtime state. Regression checks confirm the deleted treatment/hit-reaction functions are absent. Expanded checks verify the obsolete ACE evacuation switch is unregistered, the single evacuation switch defaults off, and enabled evacuation physically moves a casualty toward cover without healing or waking it. Multiplayer checks cover live settings, both joining HCs, cross-owner support, casualty and building-search handoffs, and recovery after disconnect. All eight PBO signatures verify against the supplied `vcm_3.7.0.bikey` public key.

Historical performance and building-search results below describe earlier builds. Current user-reported completion is recorded in TEST_RESULTS.md; debugger/HUD coexistence, building/room visuals, medical interactions and the other false checklist rows remain waiting.

### Historical room-search verification in 3.6.0

Full search uses sampled indoor floor areas, configured doors, explicit room membership and observed coverage. Door probes are navigation anchors, not additional mandatory search points. A door-only threshold component does not become a room. Each searched room requires physical entry on its floor and unobstructed observation of its mapped points. Inaccessible or limited layouts produce partial reports. The controller does not certify that hidden enemies are absent.

The doorway approach uses verified floor samples because some terrain buildings return below-ground `buildingExit` coordinates. Floor comparisons use absolute height so sloping terrain cannot merge different floors. Native movement and a mission-enabled native FSM handle indoor paths and stairs. The legacy FSM dispatch now schedules building searches instead of calling a suspending routine from an unscheduled action.

Run focused acceptance after building the addon:

```powershell
./tests/run-runtime.ps1 -Addon -Suite cqb
./tests/run-runtime.ps1 -Addon -Suite cqb-floors
./tests/run-multiplayer.ps1 -Addon
```

The floor suite uses a native Altis terrain house. It first proves that an uncontrolled native soldier can reach its upper floor, then requires VCOM's entry team to physically climb and search every mapped room. Script-spawned models can lack operative native building paths; they require separate acceptance. The CQB suite covers geometry, complete search, mission locks, new orders, feature disable and room limits. Multiplayer checks interrupt an active search during ownership transfer.

The 3.6.0 build uses the `hemtt` command. Static validation compiles 272 SQF files, including the 106 extracted FSM clauses, with zero errors and 340 advisory warnings. Release generation compiles 145 SQF files and eight addon configs. The signed addon is tested without embedded VCOM implementation files.

| Scenario | Result | Workspace logs |
| --- | --- | --- |
| Full native regression, vanilla | 170 checks, zero failures | `build/runtime/profiles-20261108-200115` |
| Complete CQB, limits, locks, cancellation and route telemetry, CBA/ACE | 64 checks, zero failures | `build/runtime/profiles-20261108-203942` |
| Expanded features, CBA controls and intent telemetry, CBA/ACE | 82 checks, zero failures | `build/runtime/profiles-20261108-204216` |
| Physical two-floor search, CBA/ACE | 33 checks, zero failures | `build/runtime/profiles-20261108-204346` |
| Final server/two-HC coordination, intent telemetry and CQB handoff, CBA/ACE | 68 checks, zero failures | `build/multiplayer/run-20261108-211447` |
| Final 128-unit benchmark, VCOM off | 29 checks, zero failures | `build/runtime/profiles-20261108-211642` |
| Final 128-unit benchmark, VCOM on | 29 checks, zero failures | `build/runtime/profiles-20261108-211810` |

The final handoff regression caught a reporting race: group and unit locality can change on different engine updates. Cleanup now preserves an `owner-changed` report even when the departing controller first records a partial cancellation. The final correction changes only `vcm_squad.pbo`; the seven other PBO hashes match the broader native runs above. The final focused multiplayer run loads the complete rebuilt PBO set on all three processes and proves actual entry before transfer, restored native flags, cleared sessions and exactly one new controller. The handoff fixture explicitly enables clearing and isolates legacy movement so another controller cannot consume its actors before the room task starts.

The final 128-unit vanilla benchmark uses a 15-second warmup and approximately 61 seconds per variant. Disabled averaged 28.62 server FPS (10th percentile 28.22, maximum five SQF scripts). Enabled averaged 28.81 FPS (10th percentile 28.52, maximum 47 scripts, 16 controllers). Both variants passed uniqueness, shutdown and restoration of all recorded native AI flags. Raw results are in `build/performance.csv`. This short VR scenario does not establish a speedup, measure sustained building-search load or replace long mission-specific testing. Mapping is separately bounded to one automatic job and 16 retained building layouts per owner, with configurable node/time limits; debugger sampling stops when disabled.

The intent debugger reports recorded VCOM decisions, current owner-side native command state and remembered contact positions. It cannot expose the engine's private reasoning or full native path. Dedicated-server tests cover snapshot bounds, disabled collection, actual CQB route publication and room/door telemetry. Graphical acceptance was pending for that historical build. Current gameplay panel, squad inspection, Zeus camera and display-transition checks are user-reported done; room/door/route visuals remain pending under the building-search checks. CQB geometry checks include small houses, two-floor houses and barracks; this does not establish complete traversal of every barracks or modded model.

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

The final 128-unit vanilla benchmark used a 15-second warmup and approximately 61 seconds per variant. VCOM disabled averaged 28.53 server FPS (10th percentile 28.27, maximum five active SQF scripts). Enabled averaged 28.82 FPS (10th percentile 28.52, maximum 48 scripts, 16 group controllers). Both variants passed controller uniqueness, shutdown and native AI-feature restoration checks. Historical 3.5.0 results are in `build/performance-3.5.0.csv`. FPS remained similar in this short scenario; the difference does not establish a speedup or predict another mission's performance.

These addon missions load the complete PBO set without embedded VCOM source. New checks cover bounded recovery and reservation cleanup, physical grenade trajectories and real native throw cancellation with conserved ammunition, carried smoke consumption, queued room plans, native anti-tank firing/backblast checks, three distinct squad roles, server-issued cross-owner escort leases, casualty attachment handoff, full evacuation toward improved physical cover, native convoy speed controls, pedestrian halts, CBA registration and bounded debugger data. The new global controls enter the synchronized whitelist; local overlay preferences do not. Debug-off checks verify that event histories stop growing.

Development checks caught and corrected smoke classification/command issues, premature addon CBA registration, and an invalid assumption that a headless client could query another group's owner directly. CBA registration now runs after CBA initializes its settings system, before VCOM starts. Receivers validate server-issued peer leases. The suppression fixture isolates smoke because lingering smoke correctly blocks its visibility check; the separate smoke test still requires a real native projectile and ammunition consumption. The outdoor grenade fixture waits for loaded native ammunition before firing; evacuation waits for actual contact and actor readiness. Successful runs have no SQF expression errors.

The debugger's telemetry, limits and event collection have native coverage. Graphical acceptance was pending for that historical build. Current basic panel/inspection/display checks are user-reported done; CQB destination/room visuals and other HUD compatibility remain in the pending checklist. Native `buildingPos` progression does not prove semantic room clearing, and the short convoy checks do not replace a long route test. ACE casualty evacuation remains explicit opt-in and needs mission-specific medical interaction acceptance. No FPS guarantee is made.

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

Both variants passed all three cleanup assertions: no duplicate controllers, no active controllers after shutdown, and restoration of all six recorded native AI features for every unit. There were no SQF expression errors. Logs are in `build/runtime/profiles-20261108-124630` and `build/runtime/profiles-20261108-124800`; historical raw results are in `build/performance-3.4.0.csv`. FPS remained similar in this short historical scenario. Different tactics change the native simulation workload. The user has since marked 30-minute endurance/performance acceptance complete for the tested setup (check 24); other maps and configurations require their own measurements.

## Multiplayer acceptance status

The automated suite covers local headless clients. The user has also completed the following manual cases in the tested setup; original `true` results are retained in [TEST_RESULTS.md](TEST_RESULTS.md):

- [x] Join-in-progress, applicable HC ownership transfers and multiplayer endurance as described in check 24. The exact network/machine topology was not recorded.
- [x] A 30-minute battle, performance comparison with debugging off and RPT inspection as described in check 24. No numerical benchmark results were supplied.
- [x] Vehicle/convoy spacing, pedestrian halts, dismounting, crew retention and obstacle recovery (21).
- [x] New mission orders and direct player control cancel temporary VCOM tasks without freezing units or deleting authored routes (23).

These additional or still-unmarked cases remain:

- [ ] Mission-specific ownership handoffs during rearming, artillery, resupply and other integrations beyond the completed basic HC-transfer check.
- [ ] Zeus spawning/removal and leader changes; direct player control is already completed under check 23.
- [ ] ACE treatment/evacuation with wounded soldiers, insufficient supplies, incapacitation and unreachable patients (22). ACE must retain medical control.
- [ ] Modded cargo/turret seats and new helicopter transport variants beyond the completed ground-vehicle check. Dedicated aircraft tactics are not implemented.
- [ ] Artillery with moving friendlies/civilians, translated UI and modded magazines. Its friendly-area check is a snapshot at firing time.
- [ ] The other 14 false rows in [IN_GAME_CHECKLIST.md](IN_GAME_CHECKLIST.md), including Zeus objective modules and tactical/room-search behaviors.

The server coordinates reinforcement, artillery, squad-role, anti-tank and vehicle/infantry requests across AI owners. Only server-selected fixed data is dispatched; receivers control their own local units. Remote peer owners are taken from server-issued leases because `groupOwner` can report zero for a remote group on a headless client. Completed manual acceptance applies to the user's tested setup, and the remaining cases above remain separate from those results.
