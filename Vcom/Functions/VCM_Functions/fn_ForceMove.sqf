/* Author: Genesis. Movement never replaces mission waypoints or disables AI targeting. */
params ["_leader", ["_distance", 100]];
private _group = group _leader;
if (!VCM_ADVANCEDMOVEMENT) exitWith {};
if (_group getVariable ["VCM_BoundState", []] isNotEqualTo []) exitWith {};
if (_group getVariable ["VCM_Task", []] isNotEqualTo []) exitWith {};
if (VCM_FIREMOVEMENT) exitWith {[_leader] spawn VCM_fnc_FireMove};
if (!([_group] call VCM_fnc_GroupEnabled) || {_group getVariable ["VCM_NOFLANK", false]}) exitWith {};
private _names = _group getVariable ["VCM_WaypointNames", []];
if ((waypoints _group) findIf {(_x select 1) > 0 && {!(waypointName _x in _names)}} >= 0) exitWith {};
private _enemy = _leader call VCM_fnc_ClstEmy;
if (isNull _enemy) exitWith {};
private _target = [_leader, _enemy] call VCM_fnc_ContactPosition;
if (_target isEqualTo []) exitWith {};
private _position = _leader getPos [_distance min (_leader distance2D _target), _leader getDir _target];
private _run = _group getVariable ["VCM_RunId", []];
{
    if (alive _x && {local _x} && {!isPlayer _x} && {isNull objectParent _x}) then {
        [_x, _position getPos [random 15, random 360], _run] spawn {
            params ["_unit", "_position", "_run"];
            private _group = group _unit;
            if (!([_unit, _group, _run] call VCM_fnc_ActionValid)) exitWith {};
            [_unit, _position, 30] call VCM_fnc_MoveTo;
            if ([_unit, _group, _run] call VCM_fnc_CanFollow) then {_unit doFollow leader _group};
        };
    };
} forEach units _group;
