# Arma 3 2.22 reliability and squad tactics

Future behavior requests and remaining acceptance work are tracked in [ROADMAP.md](ROADMAP.md).

This repository is the mission-script edition of VCOM. Copy `Vcom/` into the mission, include `Vcom/cfgFunctions.hpp` inside `CfgFunctions`, and execute `Vcom/VcomInit.sqf` once from mission `init.sqf`. Merge the supplied `CfgRemoteExec` with the mission's existing configuration. Do not replace other mods' required remote-function declarations.

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

Support uses two-second native [`suppressFor`](https://community.bistudio.com/wiki/suppressFor) pulses. Scripted pulses require a clear sight line and no nearby non-hostile unit in the fire corridor or near the target position. Native AI can still choose its own shots under the mission's engagement rules; these checks cannot guarantee zero friendly fire. The script does not replenish ammunition or change accuracy, combat modes, or AI features.

Turning the feature off, adding a mission waypoint, losing the contact or squad ownership, or losing an eligible participant cancels the maneuver. Cleanup releases temporary watch/movement orders. Per-unit ownership tags let a new VCOM controller release an inherited maneuver when binding its soldiers. The multiplayer regression verifies this release across a real headless-client ownership transfer and verifies controller recovery after that client disconnects.

Available settings are synchronized and exposed in CBA:

```sqf
VCM_FIREMOVEMENT = true;
VCM_COVERSEARCH = true; // Prefer physical cover at team advance destinations.
VCM_BOUNDLENGTH = 10; // Meters per team, clamped to 10–40.
VCM_BOUNDSECONDS = 12; // Seconds per team, clamped to 5–15.
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

The reliability baseline was verified locally on November 7, 2026 using Arma 3 2.22.154126, Windows x64 (the installed executable reports profiling binaries): 46 assertions passed without mods and 46 passed with the installed CBA and ACE mods.

The expanded coordination suite passed all 74 assertions without mods and all 74 with CBA and ACE using the final 10-meter, 12-second settings and inherited engagement rules. It verifies role allocation with the machine gunner placed last in the group, actual movement and native firing, both team advances, duplicate-task rejection, fire-lane vetoes, and cancellation after feature disable or a new mission order. No SQF expression errors occurred in the successful runs. A 20-meter default timed out during testing, so the default was reduced to 10 meters. HEMTT compiles 192 SQF files, including 106 extracted FSM clauses and the multiplayer test scripts, with zero errors and 125 advisory warnings remaining. The installation also emits a startup warning about `a3_characters_f`; it does not prevent the regression missions from completing.

Run the dedicated-server/headless-client regression separately:

```powershell
./tests/run-multiplayer.ps1
./tests/run-multiplayer.ps1 -Mods @('C:/path/to/@CBA_A3', 'C:/path/to/@ace')
```

This runner starts one server and two headless clients using the installed dedicated-server executable. It binds the server to `127.0.0.1:2392` and the clients to distinct loopback addresses, `127.0.0.2` and `127.0.0.3`, so their UDP ports do not collide. It starts each client after the mission is running, then deliberately terminates the first client to check ownership recovery. It stops its own processes and removes its uniquely named temporary mission. Logs remain under `build/multiplayer/run-*`. The game directory must be writable and the loopback ports must be free.

The multiplayer suite passed all 40 checks without mods and all 40 with CBA 3.19.0.260808 and ACE 3.21.2.113 on the same Arma 3 build. It covers two headless clients joining in progress, typed side/skill arrays, explicit settings replies, live updates, forged-update rejection, and ownership transfers during garrisoning, active movement, static deployment and coordinated movement. It checks that the old owner releases its controller, the new owner runs one controller with a fresh token, inherited maneuver reservations clear, pathfinding stays enabled, cancelled deployment preserves its backpack, and authored waypoints survive transfer and disconnect recovery. These are real local processes, not simulated locality flags. No SQF expression errors appeared in the server or either client's logs. Successful logs are in `build/multiplayer/run-20261107-225740` (vanilla) and `build/multiplayer/run-20261107-230220` (CBA/ACE).

## Multiplayer acceptance scenarios

The automated suite covers local headless clients. These broader acceptance checks remain:

1. Join a running mission with a graphical player client on another computer, with CBA enabled and disabled. Check that side arrays, skill arrays and activation state match the server. Change a server setting and verify it reaches the joining client.
2. Repeat ownership handoffs on a networked server with mission-specific rearming, transport and support tasks. The local suite covers garrisoning, movement, static deployment and coordinated movement; it does not exercise every task or network condition.
3. Add and remove soldiers with Zeus; change group leader; take direct player control. Check that handlers do not accumulate and authored waypoints survive.
4. Test vanilla and ACE treatment with wounded soldiers, insufficient supplies, incapacitation and unreachable patients. ACE must retain control of wounds and unconsciousness.
5. Exercise transport seats, turrets and new helicopter variants. The existing transport detector still distinguishes cargo seats; this update does not implement a dedicated aircraft tactical controller.
6. Test artillery with allies and civilians near the target, moving friendlies, translated UI and modded magazines. The friendly check is a snapshot at firing time; it cannot guarantee safety if units move into the impact area afterward.
7. Run a large mission for at least 30 minutes. Compare server frame times, scheduled-script load, stuck units and RPT errors against the previous version with the same scenario.

Reinforcement selection and artillery registries remain local to each AI owner. Coordinating support across different headless clients, advanced cover scoring, and a broader squad-level tactical planner remain separate work. Before enabling the new maneuvers in a long campaign, include them in the multiplayer and performance scenarios above.
