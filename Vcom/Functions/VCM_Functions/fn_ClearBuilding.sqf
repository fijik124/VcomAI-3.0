/* Author: Genesis. Clear remembered contact positions without piling the whole squad onto one point. */
params ["_group", "_enemy"];
private _plan = [_group,_enemy] call VCM_fnc_ClearBuildingPlan;
if (_plan isEqualTo []) exitWith {false};
_plan params ["_building","_support","_entry","_entrance","_phases","_contact"];
_group setVariable ["VCM_ClearAfter",diag_tickTime + 90];
_group setVariable ["VCM_LastClearPlan",[_building,_support,_entry,_entrance],true];
[_group,"clear",_phases,_enemy,_contact] call VCM_fnc_RunTactical
