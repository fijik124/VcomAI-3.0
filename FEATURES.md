# VCOM Edited by Fijik 3.5.0 feature guide

This update targets Arma 3 2.22 or newer. CBA and ACE are optional. Existing medical, rearming, static weapons, mines, formation, vehicle use and artillery functions remain available.

## New controls and debugger

With CBA loaded, open **Options > Addon Options > VCOM Edited by Fijik**. Feature flags and numeric controls are server/mission settings. Each feature can be disabled independently. Sliders cover recovery delays/retries/radius, grenade clearance, smoke cooldown, room count/deadline, anti-tank range/reservation, coordination radius/cooldown, planning budget/intervals, casualty distances, convoy gap/speed and retreat thresholds/deadlines. Exact defaults and limits are maintained in [fn_FeatureSettings.sqf](Vcom/Functions/VCM_Functions/fn_FeatureSettings.sqf). Saved CBA values take priority through CBA's normal server/mission setting rules. Defaults also work without CBA; the same variables are available in the supplied userconfig.

To enable the debugger:

1. Enable **Enable debugger telemetry and event log** (`VCM_Debug`) in the server/mission CBA settings.
2. On each player who needs the view, enable **Debugger: show local 3D overlay** (`VCM_DEBUGOVERLAY`). This preference is local.
3. Point at an AI group to inspect it; otherwise the nearest group with recent telemetry is selected.

Labels show group, task, role, life state and current owner. Lines show VCOM movement destinations. The panel shows local and owner FPS, task phase, last result, measured planning time, planning interval, recent events and counters. RPT events include the owner, run token and reason for task completion/cancellation, failed movement, recovery, smoke decisions and firing vetoes. Debug history is bounded (30 records per group by default); network summaries contain only the latest five events, at two-second intervals by default. Label count and range are bounded and adjustable locally. Turning the local overlay off removes its Draw3D handler, cached labels and panel. Turning telemetry off stops collection, publication and debug RPT events. Existing bounded history remains available until the mission ends. Debugging is disabled by default.

Telemetry reports observed state and wall-clock planning duration, including scheduler delays. It is a diagnostic view, not a script breakpoint debugger or a precise CPU profiler. The 3D renderer requires a graphical player client; dedicated servers and headless clients publish data without drawing.

## Additional AI behavior in 3.5.0

| Behavior | Default controls | Runtime behavior |
| --- | --- | --- |
| Stuck movers | `VCM_UNSTUCK=true`, `VCM_UNSTUCKSECONDS=4`, `VCM_UNSTUCKTRIES=3`, `VCM_UNSTUCKRADIUS=5` | Short physical alternate destinations, finite retries and unchanged task deadlines; never teleports or enables mission-disabled pathfinding. |
| Outdoor grenade safety | `VCM_GRENADESAFETY=true`, `VCM_GRENADEFRIENDLY=15` | Bounded ballistic samples reject geometry collisions and lethal impact points near non-hostiles. Rejected native throws conserve their magazine. |
| Smoke cover | `VCM_SMOKECOVER=true`, `VCM_SMOKECOOLDOWN=45` | Withdrawal/rescue support can throw carried smoke toward the threat using native ammunition. Barracks restrictions still apply. Chemlights and lethal smoke are excluded. |
| Room progression | `VCM_CQBSECTORS=true`, `VCM_CQBROOMS=8`, `VCM_CQBSECONDS=35` | Exterior staging precedes a one-mover entry queue and distinct building positions. Support watches sectors. Nearby unlocked configured doors may open; mission locks are respected. |
| Anti-tank coordination | `VCM_ATCOORD=true`, `VCM_ATRANGE=500`, `VCM_ATLEASE=20` | Server reserves a known ground vehicle for one launcher. Owner checks firing rules, front lane and a 15-meter backblast area. One rocket is allowed per reservation, with brief covering support afterward. |
| Multi-squad roles | `VCM_MULTISQUAD=true`, `VCM_COORDRANGE=500`, `VCM_COORDCOOLDOWN=45` | Server assigns at most three nearby ready radio-equipped squads assault, support and flank roles. Each owner executes bounded local movement/support tasks. |
| Cross-owner escorts | `VCM_CROSSOWNER_ESCORT=true`, plus `VCM_COMBINEDARMS` | Server leases a nearby friendly ground vehicle to an infantry group on another owner. Separate jobs stage the vehicle, screen it and unload eligible stationary passengers without changing ownership. New routes or expired leases cancel cooperation. |
| Adaptive planning | `VCM_ADAPTIVEBUDGET=true`, `VCM_BUDGETMS=3`, `VCM_NEARTICK=2`, `VCM_FARTICK=12`, `VCM_ACTIVEDISTANCE=800` | Distant idle groups plan less often. A soft per-owner/frame budget defers planning; hit/fire events wake quiet groups. Safety, binding and cleanup retain their own update rates. |
| Casualty evacuation | `VCM_CASEVAC=true`, `VCM_EVACRANGE=40`, `VCM_EVACDISTANCE=15` | A local AI rescuer can approach an unconscious squadmate and carry it toward a nearby position scoring better physical cover. Attachments and walking speed are restored on release/handoff. Medical state and supplies are unchanged. |
| Convoy control | `VCM_CONVOY=true`, `VCM_CONVOYGAP=25`, `VCM_CONVOYSPEED=45` | Groups with at least two AI ground vehicles retain their route, apply spacing/speed caps, wait for nearby non-hostile pedestrians and use bounded detours when stalled. Prior mission speed limits are preserved on release. |

Distances are meters, times are seconds, and convoy speed is km/h. ACE casualty evacuation requires explicit `VCM_ACECASEVAC=true`; it defaults false. It uses owned native attachments and reads ACE unconsciousness, without calling ACE's private drag functions or performing treatment. Mission-specific ACE interaction remains an acceptance case.

Grenade prediction uses a short gravity-only trajectory and snapshot friendly checks. Modded drag, fuses, penetration, geometry and units moving into the blast area can differ. Smoke selection recognizes non-lethal native smoke simulations with a configured smoke effect; custom effects without a smoke name need explicit mod acceptance. Room progression follows configured `buildingPos` points, not a semantic room/door navigation mesh. It does not guarantee a full building search or path around locked doors. Recovery remains subject to native pathfinding. The planning budget is soft and establishes no guaranteed FPS increase.

## Firing and indoor safety

- `VCM_WALLCHECK = true`: engaged infantry and direct-fire vehicle gunners check physical firing geometry toward the remembered target. VCOM temporarily owns the native `FIREWEAPON` feature when blocked and releases its lock when the lane clears. A local `FiredMan` handler also checks direct bullet/shell paths. Indirect artillery is exempt from straight-line checks. Scripted suppression requires both physical and visible clearance, with an additional friendly/civilian corridor check.
- `VCM_NOGRENADESINDOORS = true`: AI inside the roofed bounds of a barracks store their thrown magazines, including smoke, until they leave. A synchronous throw guard removes an indoor projectile launched between scans and conserves its magazine. Human players are excluded. Death, disable, player control and ownership changes release owned inventory state. If restored items no longer fit, they are placed in a ground holder rather than discarded.
- Barracks class names are recognized without translated display names. Add modded building base classes to `VCM_BARRACKSCLASSES = ["My_Barracks_Base"]`. The restriction concerns the thrower's location; it does not prohibit outdoor throws aimed into a building. Arbitrary mod scripts that create explosives without native firing events are outside the projectile guard.

## Infantry tactics

- `VCM_FIREMOVEMENT = true`: alternate supporting and advancing teams. Machine gunners get priority for the first support role. Default advances are 10 meters with a 15-second deadline per team. `VCM_COVERSEARCH` scores nearby physical cover and reserves separated destinations.
- `VCM_TACTICALRETREAT = true`: choose a withdrawal after at least 40% casualties from the squad's peak strength, average suppression of at least 0.65, or a severe primary-ammunition shortage. At least four original soldiers and two survivors are required. Up to 12 participants withdraw in two bounded teams, with support fire only when engagement rules and firing lanes permit. Positions favor cover and increased distance from the remembered contact. Each phase allows 25 seconds; the cooldown is 90 seconds.
- `VCM_REACTIVESUPPRESSION = true`: available squadmates provide short support pulses when another soldier is suppressed. A support task lasts three seconds, with a 12-second cooldown. It does not add ammunition or improve accuracy.
- `VCM_BUILDINGCLEARING = true`: a remembered contact inside a nearby building can produce a two-person outside support element and two to four entry soldiers. The entry team approaches an exterior staging area before moving to separate interior positions. The approach and room phases have deadlines. This does not implement explosive door breaching or guarantee a route through every modded building.

Committed movers temporarily own targeting, auto-targeting, automatic combat entry and native FSM flags, plus their movement behavior. The group temporarily suspends autonomous attack orders. Owned state is restored on role changes, completion, cancellation and locality handoff. Pathfinding remains enabled; engagement rules and skill settings are not widened. A stalled controlled mover can request a bounded native path replan, without teleporting or replacing authored waypoints. Delayed legacy actions cannot issue follow-up orders over a newer reservation.

## Support across AI owners

Reinforcement and artillery requests now pass through a server coordinator. Headless-client requests resolve their identity against the requesting group's current owner; player-client requests use the engine sender ID. Messages contain fixed data, not executable code or arbitrary recipient IDs.

- `VCM_CROSSOWNER_SUPPORT = true`: up to two eligible friendly infantry groups can respond, including groups owned by other headless clients. Responders recheck radio availability, commitments, mission waypoints and group opt-outs on their own machines.
- Artillery can use guns owned by another AI machine. The gun owner rechecks HE ammunition, range, firing rules, activation state and nearby non-hostiles before firing. A request dispatches at most two guns and at most three rounds per gun. Request and asset cooldowns limit repeat orders. Friendly checks are snapshots and cannot guarantee safety if units enter the impact area afterward.

## Infantry and ground vehicles

`VCM_COMBINEDARMS = true` coordinates separate friendly infantry and AI ground-vehicle groups. The original same-owner planner uses known contacts 80–600 meters away, bounded vehicle staging and infantry screen positions behind the vehicle. Stationary transports can unload assigned infantry at a suitable standoff while retaining their driver and gunner. Version 3.5.0 also provides server-issued cross-owner escorts through `VCM_CROSSOWNER_ESCORT`. Authored vehicle or infantry routes cancel autonomous cooperation. Aircraft tactics remain outside this controller.

## Mission control

All feature toggles above are synchronized server settings and CBA checkboxes. Existing `Vcm_Disable`, `VCM_NOFLANK`, `VCM_NORESCUE`, `VCM_TOUGHSQUAD` and skill/formation opt-outs remain supported. `VCM_NOARTY` opts an artillery group out of automatic fire missions. `VCM_NOAUTOTACTICS` skips the periodic new tactical-task planner; use `VCM_NOFLANK` to prohibit all autonomous movement for a group.

## Performance work

- Native contacts and individual remembered positions are reused within the same simulation frame, without carrying reveal results into a later frame. Crew and passengers share their platform's contact query.
- Safety scans run at most twice per second per unit. Indoor geometry is cached briefly for stationary units; an actual throw always requests a fresh indoor check. Throwable classification is prepared once from config. Empty inventories skip indoor geometry checks.
- Routine grenade checks read only magazine class names; full ammunition records are allocated when an indoor inventory actually needs storage. Mounted crew skip this inventory scan.
- Committed tasks, small squads and opted-out groups skip unnecessary tactical planning. The automatic group scanner uses the local controller token instead of repeatedly searching the active-group array.
- Mine simulation remains native. Empty registries return immediately; registry pruning runs once per second. Expired support-request records are periodically removed.
- Searches, support pulses, moves and tasks have bounded work or deadlines. No new per-frame global entity scanner is installed.

Run `./tests/run-performance.ps1 -Addon` for sequential VCOM-off/on measurements using the same 128-unit VR combat setup. It records mean FPS, 10th-percentile FPS, active script counts and cleanup checks in `build/performance.csv`. This is a repeatable stress smoke test, not a guarantee for another map, modset or long campaign. Use `-Seconds 1800` for a 30-minute measurement of each variant.

The final 3.5.0 benchmark averaged 28.53 server FPS disabled and 28.82 enabled over approximately 61 seconds per variant on November 8, 2026. All 16 enabled squad controllers shut down cleanly, with no duplicated controllers or unrestored native AI flags. FPS remained similar; this short run does not establish a speedup. The eight-PBO layout itself establishes no FPS increase. See [MIGRATION.md](MIGRATION.md) for verification results, the historical 3.4.0 measurement and log locations.

## Build and install

`node tools/build-release.mjs` runs the `hemtt release --no-bin` command and writes the signed addon under `build/upload/@VCOM_Edited_by_Fijik`. Its eight PBOs separate core, squad, vehicle, safety, support, medical, equipment and startup responsibilities. Each PBO has its own signature; one public verification key covers the complete build. Load the mod on the server, headless clients and player clients. Keep the full PBO set together and disable behavior through settings. The addon starts automatically; remove older VCOM addons, including `@VCOM_AI`, and embedded mission-script copies to avoid conflicting functions. The supplied key belongs in the server's `keys` folder when signature verification is enabled. No private key is included in the upload folder. The module map is in [README.md](README.md).

For a mission with restrictive remote-execution settings, merge the supplied `REMOTE-EXEC.hpp` declarations. The addon does not replace another mod's global remote-execution policy. See [MIGRATION.md](MIGRATION.md) for mission-script installation, legacy settings and validation results.

After validating the PBOs, run `./tools/package-upload.ps1` to create `build/upload/VCOM_Edited_by_Fijik-3.5.0.zip` and its SHA-256 checksum. Documentation refreshes without rebuilding or changing the tested PBOs and signatures. The eight-PBO layout provides separate files for maintenance and updates.
