/* Author: Genesis. Only the current squad run may pack its deployed weapon. */
params ["_unit", "_backpack", "_weapon", ["_run", []]];
private _group = group _unit;
if (_run isEqualTo []) then {_run = _group getVariable ["VCM_RunId", []]};
private _deadline = diag_tickTime + 180;
waitUntil {
    sleep 1;
    !([_unit, _group, _run] call VCM_fnc_ActionValid) || {!alive _weapon} || {diag_tickTime >= _deadline}
};
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {!alive _weapon} ||
    {crew _weapon findIf {_x != _unit} >= 0} || {backpack _unit != ""}) exitWith {};
unassignVehicle _unit;
_unit leaveVehicle _weapon;
doGetOut _unit;
sleep 2;
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {count crew _weapon > 0} || {backpack _unit != ""}) exitWith {};
deleteVehicle _weapon;
_unit addBackpackGlobal _backpack;
