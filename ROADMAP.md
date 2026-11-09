# VCOM Edited by Fijik roadmap

## AI decision debugger in 3.6.0

- Show each group's recorded VCOM action, native commands, roles, remembered threat and reason for choosing its plan.
- Draw intended destinations, planned CQB routes, door state and observed room coverage.
- Explain safety holds, locked doors, retries, cancellations and incomplete searches.
- Keep visualization optional through CBA, with bounded snapshots, distance limits and update intervals.

## Room search in 3.6.0

- Expand native building positions with physical floor samples and a cached door/floor graph.
- Stack at a verified doorway and move one entry soldier at a time while others cover.
- Retain native indoor path behavior for stairs and door interaction.
- Track room entry, observed coverage, blocked rooms and partial-search reasons.
- Honor mission locks, task cancellation and ownership changes; retain interrupted reports.
- Expose full-search, room, node, observation and time limits through CBA and show progress in the debugger.

Native acceptance results and model limits are recorded in [MIGRATION.md](MIGRATION.md).

## Implemented for 3.5.0

All ten requested additions have runtime implementations. The native acceptance matrix and remaining limits are recorded in [MIGRATION.md](MIGRATION.md); feature controls are described in [FEATURES.md](FEATURES.md).

1. Stuck-unit recovery with alternate destinations, retry limits and clean failure.
2. Outdoor grenade trajectory and friendly blast-area checks, with ammunition conservation.
3. Native smoke throws covering withdrawal and casualty recovery.
4. Doorway queues, sectors and staged room progression during building clearing.
5. Anti-tank target reservations, firing-lane/backblast checks and reload cover.
6. Multi-squad assault, support and flank assignments through the server coordinator.
7. Infantry/vehicle cooperation across headless-client owners without transferring ownership.
8. Adaptive planning intervals and a soft processing budget, preserving urgent safety and cleanup checks.
9. AI casualty evacuation toward cover, with ACE-aware eligibility and owned attachment cleanup.
10. Convoy spacing, coordinated halts, pedestrian protection and bounded obstacle recovery.

User-requested controls are implemented: CBA feature switches and tunable distances, cooldowns, retry counts and processing limits. The CBA-toggleable debugger includes role/destination overlays, bounded task history, failure reasons and owner/performance counters. Its local drawing handler and panel are removed when the overlay is disabled. Telemetry and event logging are disabled by default.

## Packaging in 3.4.1

- Renamed the project and launcher entry to VCOM Edited by Fijik, retaining credit for original author Genesis.
- Split the addon into eight signed PBOs for core, squad, vehicles, safety, support, medical, equipment and startup. All eight remain required; feature switches control optional behavior.
- Preserved mission-script paths, settings IDs and public function names. The split changes packaging, with no additional AI scheduler loops.

## Implemented in 3.4.0

- Cover selection during coordinated advances now scores nearby physical obstructions against the remembered threat position and keeps destination spacing between teammates. It is enabled by default and can be switched off through `VCM_COVERSEARCH`. Native geometry, movement and cancellation checks pass with and without CBA/ACE. See [MIGRATION.md](MIGRATION.md) for validation results and limits.

## Requested behaviors

1. **Wall-aware firing:** physical firing-lane checks for engaged infantry and direct-fire vehicle gunners, a native firing-feature lock and a synchronous projectile guard. Open lanes restore VCOM-owned firing state. Indirect artillery retains its range and impact-area checks.
2. **Grenade restrictions inside barracks:** roof and building-bounds detection, conserved throwable inventory, an actual-throw guard and restoration outdoors. Modded barracks classes can be configured. The restriction applies to the thrower's location, including smoke grenades.

See [FEATURES.md](FEATURES.md) for settings, thresholds, installation and practical limits. Modded geometry and scripts that create projectiles without native firing events require separate acceptance testing.

## Additional implemented features

- Short reactive suppression tasks and two-team tactical retreat based on casualties, ammunition and combat pressure.
- Server-coordinated reinforcement and HE artillery requests across headless-client owners, with owner-side revalidation and rate limits.
- Building clearing with outside support, exterior staging and distinct entry positions.
- Same-owner cooperation between infantry and ground vehicles, including bounded staging, infantry screens and transport unloading that retains the crew.
- Frame-local contact reuse, timed safety scans, cached throwable classification, bounded path replans and cheap empty-registry checks. A reproducible VCOM-off/on performance runner records 128-unit combat measurements.
- Signed PBO and upload-folder generation through the `hemtt` command.

## Remaining acceptance checks

- Visual review of the debugger labels, routes, room/door markers and panel on a graphical player client.
- Complete traversal of more terrain and modded buildings, especially large barracks and unusual floor/door models.
- Graphical player clients joining from another computer, with and without CBA/ACE.
- Zeus spawning, leader changes and direct player control.
- Mission-specific medical, rearming, transport and artillery cases.
- At least 30 minutes of large-battle performance measurement against a matching baseline.
