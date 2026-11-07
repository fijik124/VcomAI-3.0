# AI development roadmap

## In progress

- Improve cover selection during coordinated advances. Score nearby physical obstructions against the remembered threat position and keep destination spacing between teammates. Validate native movement, cancellation, settings synchronization and headless-client transfers.

## Next requested behaviors

1. **Wall-aware firing.** Improve environmental awareness so AI avoid firing at enemies through solid walls. Check the firing path against physical geometry and distinguish an obstructing wall from an opening. Verify both VCOM-scripted suppression and native AI firing; the existing scripted sight-line check alone does not establish this behavior for every shot.
2. **Grenade restrictions inside barracks.** Prevent AI from throwing grenades while inside a barracks building. Preserve grenade use outdoors. Verify indoor/outdoor detection at doors, windows and entrances, including modded barracks. This request currently applies to barracks; extending it to every building is a separate scope decision.

These two behaviors are requested work, not implemented guarantees.

## Further improvements

- Suppression and tactical retreat based on casualties, ammunition and combat pressure.
- Reinforcement and artillery coordination across headless-client owners.
- Building clearing with entry and support roles.
- Coordination between infantry, transports and armed vehicles.

## Remaining acceptance checks

- Graphical player clients joining from another computer, with and without CBA/ACE.
- Zeus spawning, leader changes and direct player control.
- Mission-specific medical, rearming, transport and artillery cases.
- At least 30 minutes of large-battle performance measurement against a matching baseline.
