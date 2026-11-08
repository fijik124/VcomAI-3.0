/* Author: Genesis. Timed rearm approach; stop when dead, disabled, or transferred. */
params ["_unit", "_source", ["_run", []]];
private _group = group _unit;
if (_run isEqualTo []) then {_run = _group getVariable ["VCM_RunId", []]};
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {isNull _source}) exitWith {};
private _arrived = [_unit, getPosATL _source, 40, {!isNull _source}] call VCM_fnc_MoveTo;
if (_arrived && {!isNull _source} && {_unit distance _source < 6}) then {_unit action ["Rearm", _source]};
if ([_unit, _group, _run] call VCM_fnc_CanFollow) then {_unit doFollow leader _group};
