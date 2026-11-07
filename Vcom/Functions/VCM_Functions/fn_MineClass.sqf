/* createMine takes a CfgVehicles class; inventory magazines reference CfgAmmo instead. */
params ["_ammo"];
if (isNil "VCM_MineClasses") then {VCM_MineClasses = []};
private _cached = VCM_MineClasses findIf {(_x select 0) isEqualTo _ammo};
if (_cached >= 0) exitWith {VCM_MineClasses select _cached select 1};
private _classes = ("true" configClasses (configFile >> "CfgVehicles")) select {
    getText (_x >> "ammo") isEqualTo _ammo
};
private _class = "";
if (count _classes > 0) then {_class = configName (_classes select 0)};
VCM_MineClasses pushBack [_ammo, _class];
_class
