/* Author: Genesis. Clear remembered contact positions without piling the whole squad onto one point. */
params ["_group", "_enemy"];
if (_group getVariable ["VCM_BoundState", []] isNotEqualTo []) exitWith {};
if (!([_group] call VCM_fnc_GroupEnabled) || {isNull _enemy} || {_group getVariable ["VCM_NOFLANK", false]}) exitWith {};
private _position = [leader _group, _enemy] call VCM_fnc_ContactPosition;
if (_position isEqualTo []) exitWith {};
private _buildings = nearestObjects [_position, ["House", "Building"], 25];
_buildings = _buildings select {count (_x buildingPos -1) > 3};
if (_buildings isEqualTo []) exitWith {};
private _positions = (_buildings select 0) buildingPos -1;
private _run = _group getVariable ["VCM_RunId", []];
{
    if (_positions isEqualTo []) exitWith {};
    if (alive _x && {local _x} && {!isPlayer _x} && {isNull objectParent _x}) then {
        [_x, _positions deleteAt 0, _run] spawn {
            params ["_unit", "_position", "_run"];
            private _group = group _unit;
            if (!([_unit, _group, _run] call VCM_fnc_ActionValid)) exitWith {};
            [_unit, _position, 45] call VCM_fnc_MoveTo;
            if ([_unit, _group, _run] call VCM_fnc_ActionValid && {_unit != leader _group}) then {_unit doFollow leader _group};
        };
    };
} forEach units _group;
