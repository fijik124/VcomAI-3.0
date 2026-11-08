/* Replan only for a current local reservation. Do not create or replace mission waypoints. */
params ["_unit","_position","_run",["_key",[]]];
private _group = group _unit;
if (!([_unit,_group,_run] call VCM_fnc_ActionValid)) exitWith {false};
private _task = _unit getVariable ["VCM_TaskKey",[]];
private _bound = _unit getVariable ["VCM_BoundKey",[]];
if ((_task isNotEqualTo [] && {!(_task isEqualTo _key)}) ||
    {_bound isNotEqualTo [] && {!(_bound isEqualTo _key)}}) exitWith {false};
if (_key isNotEqualTo []) then {
    _unit doTarget objNull;
    _unit doFire objNull;
};
doStop _unit;
if (_key isNotEqualTo []) then {[_unit] commandMove _position};
_unit doMove _position;
if (_key isNotEqualTo []) then {_unit setDestination [_position,"LEADER PLANNED",true]};
if (VCM_Debug) then {_unit setVariable ["VCM_DebugMove",[time,_position,_key],true]};
true
