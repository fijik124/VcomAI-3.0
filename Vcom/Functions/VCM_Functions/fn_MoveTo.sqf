/* Scheduled, bounded movement. The caller retains responsibility for follow-up orders. */
params ["_unit", "_position", ["_timeout", 45], ["_guard", {true}], ["_taskKey",[]]];
private _group = group _unit;
private _run = _group getVariable ["VCM_RunId", []];
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {!(_unit checkAIFeature "PATH")}) exitWith {false};
if (!((_unit getVariable ["VCM_TaskKey",[]]) isEqualTo _taskKey)) exitWith {false};
if (_unit getVariable ["VCM_MoveKey", []] isNotEqualTo [] || {_group getVariable ["VCM_BoundState", []] isNotEqualTo []}) exitWith {false};
private _moveKey = [_run, diag_tickTime];
_unit setVariable ["VCM_MoveKey", _moveKey];
private _deadline = diag_tickTime + _timeout;
[_unit,_position,_run,_taskKey] call VCM_fnc_IssueMove;
private _nextReplan = diag_tickTime + VCM_UNSTUCKSECONDS;
private _lastPosition = getPosATL _unit;
private _leg = _position;
private _attempt = 0;
private _exhausted = false;
waitUntil {
    sleep 0.25;
    if (_leg isNotEqualTo _position && {_unit distance _leg < 2}) then {
        _leg = _position;
        [_unit,_leg,_run,_taskKey] call VCM_fnc_IssueMove;
    };
    if (_taskKey isNotEqualTo [] && {diag_tickTime >= _nextReplan} &&
        {[_unit,_group,_run] call VCM_fnc_ActionValid} && {[_unit,_group] call _guard} &&
        {(_unit getVariable ["VCM_TaskKey",[]]) isEqualTo _taskKey}) then {
        // Native subformation orders can divert a moving soldier as well as stop one.
        private _diverted = ((expectedDestination _unit) select 0) distance _position > 3;
        private _stalled = _unit distance _lastPosition < 0.75;
        if (_stalled && {VCM_UNSTUCK} && {_unit distance _position > 2}) then {
            _attempt = _attempt + 1;
            if (_attempt > floor VCM_UNSTUCKTRIES) then {_exhausted = true} else {
                private _alternate = [_unit,_position,_run,_taskKey,_attempt] call VCM_fnc_RecoveryPosition;
                if (_alternate isNotEqualTo []) then {_leg = _alternate};
            };
        };
        if (!_exhausted && {(_diverted || {_stalled})} && {_unit distance _position > 2}) then {[_unit,_leg,_run,_taskKey] call VCM_fnc_IssueMove};
        _lastPosition = getPosATL _unit;
        _nextReplan = diag_tickTime + VCM_UNSTUCKSECONDS;
    };
    !([_unit, _group, _run] call VCM_fnc_ActionValid) || {!([_unit, _group] call _guard)} ||
    {!((_unit getVariable ["VCM_TaskKey",[]]) isEqualTo _taskKey)} ||
    {_exhausted} || {diag_tickTime >= _deadline} || {_unit distance _position < 2}
};
private _arrived = [_unit, _group, _run] call VCM_fnc_ActionValid && {[_unit, _group] call _guard} &&
    {(_unit getVariable ["VCM_TaskKey",[]]) isEqualTo _taskKey} && {_unit distance _position < 2};
if (_moveKey isEqualTo (_unit getVariable ["VCM_MoveKey", []])) then {_unit setVariable ["VCM_MoveKey", nil]};
if (!_arrived) then {[group _unit,"move-failed",format ["%1 goal %2 attempts %3",_unit,_position,_attempt]] call VCM_fnc_DebugTrace};
_arrived
