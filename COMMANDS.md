# VCOM tactical orders, doctrine and Zeus controls

Version 3.8.0 adds counter-flanking, reconnaissance, night equipment discipline, defensive positions, per-squad doctrine and bounded tactical danger memory. CBA_A3 and ACE including Medical remain required.

## Autonomous behavior

All six systems operate without Zeus maintenance. Small AI elements choose reconnaissance, observe and report. Supplied squads with a usable contact can choose assault. Known pressure, unfavorable contact numbers or squad losses favor defense. Multi-vehicle groups use the existing convoy controller. Normal retreat still selects cover automatically; a marked fallback point is an optional override.

Automatic doctrine uses native remembered contacts, squad condition and carried equipment. It does not inspect hidden enemy positions. Roles are reconsidered at bounded planning intervals with a 20-second hold to reduce rapid switching. Mission routes and group opt-outs take priority. No autonomous doctrine creates a permanent Zeus point.

Night discipline chooses equipped IR lasers, flashlights and carried hand flares according to darkness, NVG, contact distance and recon stealth. Danger memory and counter-flanking react to observed events. CBA settings provide global permissions and limits; ordinary use requires no per-squad setup.

## Zeus workflow

The signed addon adds eight optional point/reset modules under **Modules > VCOM Tactics**. Use them to give a specific objective, override a fallback position, mark a known danger area, or clear an override. Mission makers must allow the VCOM addon in their curator's available addons. A curator can command only squads whose leaders are editable by that curator.

1. Select one or more AI squads in Zeus, then place a VCOM module within 30 seconds. Up to sixteen selected squads are accepted.
2. Alternatively, drop a module directly on an AI soldier to target that soldier's squad.
3. Place an observation, defense or fallback module at the desired position. Each squad has one active observation/defense assignment and one optional fallback assignment.
4. Place another module of the same purpose for that squad to move the assignment. A new observation or defense point replaces the previous observation/defense point.

Orders use fixed data sent to the server. The server checks the sender's assigned curator, editable squads, point type, coordinates, limits and request rate. Headless clients cannot issue curator orders. Execution stays on the squad's current owner; commands do not transfer ownership.

Normal mission waypoints, group opt-outs, direct player control and survival tasks take priority. Point placement does not delete authored waypoints. An assigned point becomes eligible when the squad has no conflicting mission route or reservation.

## Points and reset modules

| Module | Result |
| --- | --- |
| Recon observation point | Move two teams to separated observation positions, hold fire except for return fire, and report remembered contacts. |
| Defend position | Establish covered, spaced positions and individual watch sectors around the point. |
| Fallback position | Use the assigned area when the squad's normal casualty, suppression or ammunition criteria trigger a retreat. |
| Mark danger area | Penalize movement destinations inside the marked area for the selected squads. Up to eight manual areas per squad. |
| Restart nearest VCOM point (50 m) | Keep the nearest observation/defense/fallback point, cancel its current task and restart its planning. |
| Remove nearest VCOM point (50 m) | Delete the nearest assignment and cancel its current task. Points at the same position for multiple squads are removed together. |
| Forget danger near this point | Remove remembered danger within the module's radius for the selected squads. Explicit danger-area assignments remain until removed. |
| Reset squad tactics and points | Clear the selected squads' overrides, threat axis and danger memory. Cancel their reservations and return them to automatic decisions. |

Yellow local markers identify assigned points. Red markers show explicit danger areas. Orange markers show the selected squads' recent fire, casualty and failed-movement memory, including expiry time. Markers exist only while the authorized curator interface is open and disappear when it closes. Ordinary player maps receive no VCOM tactical markers. The registry retains at most 64 explicit points, and the overlay shows memory for at most four selected squads.

The default point radius is 30 meters. CBA exposes radius, maximum squad-to-point distance, movement deadline, hold duration and replanning interval. Outdoor posts allow up to five meters of native stopping tolerance. A soldier stopping short must retain the planned physical protection; otherwise the task reports incomplete movement. CQB retains its existing precise movement checks. Eden modules expose a radius attribute. The module's orientation supplies the initial defensive heading; known contacts can focus the watch direction.

## Automatic doctrine and optional Eden presets

Automatic selection is the default. Five Eden-only modules let mission authors pin a doctrine or return a squad to automatic decisions. These presets are not exposed as routine Zeus maintenance controls. The mission API can also set an explicit override.

| Preset | Behavior |
| --- | --- |
| Automatic | Choose a role from current squad condition and known contacts; use existing VCOM tactics when no special role fits. |
| Cautious reconnaissance | Observe from a standoff position, report real remembered contacts and avoid autonomous assaults. Eligible soldiers temporarily use return-fire rules. Incoming fire or significant suppression releases the restriction. |
| Assault | Use standard assault behaviors with a shorter coordinated-advance cooldown: 30 seconds instead of 45. Engagement rules, ammunition and skills stay mission-controlled. |
| Static defense | Anchor around the assigned point, or the squad's location when defense begins. Establish spaced positions and watch sectors. |
| Convoy escort | Prioritize the native route and existing convoy controller, use file formation when available, and avoid unrelated autonomous infantry assaults. |

Doctrines do not change skill, replenish supplies or widen mission engagement rules. Formation preferences yield to authored routes and formation opt-outs. Turning `VCM_DOCTRINES` off releases owned formation and reconnaissance restrictions. Explicit points retain their own feature switches.

## Counter-flanking

The owner records a threat bearing from native contacts. A known contact entering a sufficiently different bearing can trigger a short reposition by up to two soldiers while teammates cover. The planner uses remembered positions and existing firing-lane checks. It does not scan hidden enemies. Range, bearing threshold, movement radius and cooldown are configurable in CBA. Authored routes, existing tactical reservations and group opt-outs remain authoritative.

## Reconnaissance reports

Radio-equipped reconnaissance squads can report up to four actual remembered contacts per report. The server distributes the reported positions to at most three nearby friendly radio-equipped AI squads. Each recipient retains at most eight reports for 30 seconds. Native contacts take priority over reports.

The report contains the observer's remembered position. It does not issue a native reveal command or replace that position with the target's current location. A reporting squad must be controlled by the requesting owner. The default report interval is 30 seconds and radio range is 1,000 meters.

## Night discipline

Night equipment decisions are automatic. The mission API supports three optional overrides:

- **Automatic:** troops with NVG may use equipped IR lasers during contact. Flashlights and hand flares require their CBA permission.
- **Blackout:** suppress managed weapon lights and IR lasers, and prohibit automatic hand flares.
- **Illumination allowed:** permit flashlights and carried hand flares for troops without NVG during contact.

Recon doctrine and observation orders retain blackout behavior. No equipment or ammunition is added. Flares use carried non-lethal ACE hand flares and real native throws, including existing indoor and trajectory checks. Flashlights and hand flares require a remembered contact within 150 meters. The default flare cooldown is 90 seconds. Parachute flares and automatic grenade-launcher flare firing are outside this controller.

Night discipline records observed attachment states and owns the native `LIGHTS` feature only while active. It releases its state during daylight, disable, player control and ownership changes. Mission-disabled lights and player-containing squads are respected. Use `VCM_NONIGHT=true` on a group to opt it out. CBA flashlight and hand-flare permissions default to true; saved mission settings remain authoritative.

## Tactical danger memory

The squad owner records observed incoming fire, casualties and failed outdoor movement. Nearby observations merge. Defaults are 24 records per squad, five minutes of retention and a 25-meter influence radius. Advances, flanks, retreats, recovery moves and observation/defense positions rank destinations using this memory.

Native pathfinding controls the route actually walked. The memory ranks destinations; it does not install a custom navigation mesh. Rooms and indoor paths remain controlled by the existing CQB system. Memory survives ownership transfer through bounded group data and expires without persistent campaign storage.

## Eden and mission scripts

In Eden, place a VCOM module and synchronize the desired AI soldiers to it. The module derives squads from those synchronized soldiers. Zeus modules require the addon; mission-script installations can use the same server API directly.

Examples below run on the server:

```sqf
// Optional mission-authored doctrine override. Ordinary AI needs no call.
[objNull, "doctrine", "recon", [mySquad], getPosATL leader mySquad, 0, 30] call VCM_fnc_CommanderOrder;

// Establish a defensive area facing east.
[objNull, "point", "defend", [mySquad], [5000, 5000, 0], 90, 30] call VCM_fnc_CommanderOrder;

// Set a separate fallback position.
[objNull, "point", "fallback", [mySquad], [4900, 5000, 0], 90, 20] call VCM_fnc_CommanderOrder;

// Restart the point closest to this location without deleting it.
[objNull, "restartPoint", "", [], [5000, 5000, 0], 0, 30] call VCM_fnc_CommanderOrder;

// Remove the nearest point within 50 meters.
[objNull, "resetPoint", "", [], [5000, 5000, 0], 0, 30] call VCM_fnc_CommanderOrder;

// Forget recent danger in a 30-meter area.
[objNull, "resetDanger", "", [mySquad], [5000, 5000, 0], 0, 30] call VCM_fnc_CommanderOrder;

// Return the squad's VCOM command state to defaults.
[objNull, "resetGroup", "", [mySquad], getPosATL leader mySquad, 0, 30] call VCM_fnc_CommanderOrder;
```

Server-side mission scripts call `VCM_fnc_CommanderOrder` with `objNull`; this function is absent from the remote-execution whitelist. Zeus clients use `VCM_fnc_CommanderRequest` with their actual curator player as the first argument. Requests from ordinary players, headless clients or a null identity are rejected. Server-local recon uses `VCM_fnc_ReconPublish`; remote owner reports use `VCM_fnc_ReconReport`. Inputs contain no executable code or client-chosen owner IDs.

## Verification

```powershell
node tests/validate.mjs
node tools/build-release.mjs
./tests/run-runtime.ps1 -Addon -Suite doctrine -TimeoutSeconds 480
./tests/run-multiplayer.ps1 -Addon -TimeoutSeconds 600
```

The native doctrine suite exercises autonomous role selection, movement without command points, counter-flanking, recon reports, defense cancellation, fallback travel, carried illumination and the native module entry. Multiplayer coverage checks optional-point synchronization on join, HC execution, restarts, ownership handoffs, danger resets and forged requests. Graphical Zeus selection, marker readability and module placement still need visual acceptance on a player client.
