/* Classify by ammo configuration; UI labels may be translated. Overrides support modded ammunition. */
params ["_magazine"];
private _override = VCM_ARTYAMMOOVERRIDES findIf {(_x select 0) isEqualTo _magazine};
if (_override >= 0) exitWith {toUpper (VCM_ARTYAMMOOVERRIDES select _override select 1)};
private _ammo = configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
private _simulation = toLower getText (_ammo >> "simulation");
if (_simulation in ["shotsmokex", "shotsmoke"]) exitWith {"SMOKE"};
private _submunition = configFile >> "CfgAmmo" >> getText (_ammo >> "submunitionAmmo");
if (toLower getText (_submunition >> "simulation") in ["shotsmokex", "shotsmoke"]) exitWith {"SMOKE"};
// Unknown submunitions, illumination and mine delivery require explicit opt-in.
if (getText (_ammo >> "submunitionAmmo") != "" || {_simulation == "shotilluminating"}) exitWith {"IGNORE"};
if (getNumber (_ammo >> "laserLock") > 0 || {getNumber (_ammo >> "irLock") > 0}) exitWith {"GUIDED"};
if (getNumber (_ammo >> "indirectHit") > 0 && {getNumber (_ammo >> "explosive") > 0}) exitWith {"HE"};
"IGNORE"
