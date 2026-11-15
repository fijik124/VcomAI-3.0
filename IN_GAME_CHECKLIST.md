# VCOM 3.8.0 pending in-game verification checklist

**14 checks are waiting; 10 completed checks are archived in [TEST_RESULTS.md](TEST_RESULTS.md).** Original check IDs are preserved.

Change **Done** to `true` when a check passes. Leave it `false` while waiting, untested or failing, and explain the result in **Notes**. Completed rows can then be moved to the results file.

## Test session

- Date:
- Tester:
- Mission / terrain:
- VCOM build:
- Other mods:
- Server / hosting type:
- Headless clients:
- RPT / video / screenshots:

Load CBA, ACE Medical and the updated VCOM on every machine. Restart Arma after replacing the addon. Start with a small mission and AI-led squads, then repeat with your normal mod set. Let AI actually spot enemies; authored waypoints can take priority over autonomous tactics.

| ID | Check | Passing result | Done | Notes |
| --- | --- | --- | --- | --- |
| 07 | Other HUDs | Mission hints, radio messages and ACE interactions do not replace the debugger panel. | false | |
| 08 | Missing data | Moving outside draw distance produces a waiting-for-telemetry message. | false | |
| 09 | Disable debugging | Disabling the main debugger or local overlay removes its panel, labels and lines. | false | |
| 10 | Fire and movement | At least four eligible infantry facing a known enemy alternate movement and covering roles and physically travel toward intended destinations. | false | |
| 11 | Counter-flanking | A newly observed threat from another direction can trigger a short reposition while teammates cover. | false | |
| 12 | Reconnaissance | Scout elements observe cautiously and report known contacts instead of immediately charging. | false | |
| 13 | Defense and withdrawal | Sufficient pressure or losses can trigger spaced defenses or withdrawal; an assigned fallback influences a retreat when its criteria trigger. | false | |
| 14 | Zeus orders | Recon, defense and fallback assignments work; restart, removal and squad reset work; tactical markers appear only in the authorized curator view. | false | |
| 15 | Building clearing | A small house, two-floor house and barracks show staged entry, covering soldiers, physical floor traversal and changing room status. Record each building tested. | false | |
| 16 | Locked rooms | Locked doors remain respected, and inaccessible areas produce an incomplete/partial report. Searched means mapped areas were observed, not that every hidden enemy is dead. | false | |
| 18 | Grenade handling | Restricted grenades remain conserved inside barracks and become available again outdoors. | false | |
| 19 | Smoke and anti-tank | Real smoke throws consume carried ammunition; launcher fire is coordinated; a friendly behind a launcher can veto its backblast lane. | false | |
| 20 | Night equipment | Equipped flashlights, NVGs/IR lasers and carried ACE hand flares behave according to contact and stealth conditions without creating equipment or ammunition. | false | |
| 22 | ACE evacuation | With casualty evacuation explicitly enabled, a casualty physically moves toward cover, detaches afterward and remains under ACE medical control. | false | |

## Failure details

Copy this block for each problem:

- Check ID:
- Expected result:
- Actual result:
- Steps to reproduce:
- Terrain / building:
- AI group size:
- Debugger task / reason:
- Mods:
- Screenshot / video / RPT:
- Retest result:
