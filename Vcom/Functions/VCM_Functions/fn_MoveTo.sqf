/* Scheduled, bounded movement. The caller retains responsibility for follow-up orders. */
params ["_unit", "_position", ["_timeout", 45], ["_guard", {true}]];
private _group = group _unit;
private _run = _group getVariable ["VCM_RunId", []];
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {!(_unit checkAIFeature "PATH")}) exitWith {false};
if (_unit getVariable ["VCM_MoveKey", []] isNotEqualTo [] || {_group getVariable ["VCM_BoundState", []] isNotEqualTo []}) exitWith {false};
private _moveKey = [_run, diag_tickTime];
_unit setVariable ["VCM_MoveKey", _moveKey];
private _deadline = diag_tickTime + _timeout;
doStop _unit;
_unit doMove _position;
waitUntil {
    sleep 0.25;
    !([_unit, _group, _run] call VCM_fnc_ActionValid) || {!([_unit, _group] call _guard)} ||
    {diag_tickTime >= _deadline} || {_unit distance _position < 2}
};
private _arrived = [_unit, _group, _run] call VCM_fnc_ActionValid && {[_unit, _group] call _guard} && {_unit distance _position < 2};
if (_moveKey isEqualTo (_unit getVariable ["VCM_MoveKey", []])) then {_unit setVariable ["VCM_MoveKey", nil]};
_arrived
