/* Two bounded advances. Keep both teams in their original group and preserve native AI features. */
params ["_leader"];
private _plan = [_leader] call VCM_fnc_FireMovePlan;
if (_plan isEqualTo []) exitWith {};
_plan params ["_enemy", "_position", "_teamA", "_teamB", "_run"];
private _group = group _leader;
private _serial = 1 + (_group getVariable ["VCM_BoundSerial", 0]);
private _key = [_run, _serial];
private _units = _teamA + _teamB;
private _state = [_key, _units, 0, [], [], [], [0,0]];
_group setVariable ["VCM_BoundSerial", _serial];
_group setVariable ["VCM_BoundState", _state];
_group setVariable ["VCM_Committed",true,true];
[_group,"bound","Advance one team while the other supplies physical covering fire",[],_position] call VCM_fnc_DebugDecision;
[_group,_key] call VCM_fnc_AttackControl;
_group setVariable ["VCM_NextBound", diag_tickTime + 45];
{_x setVariable ["VCM_BoundKey", _key, true]} forEach _units;
[_group] call VCM_fnc_ClearWaypoints;
private _valid = {
    !isNull _enemy && {[_group, _run, _enemy] call VCM_fnc_FireMoveReady} &&
    {(_group getVariable ["VCM_BoundState", []]) isEqualTo _state} &&
    {_units findIf {!([_x, _group, _run] call VCM_fnc_BoundUnitReady) ||
        {!((_x getVariable ["VCM_BoundKey", []]) isEqualTo _key)}} < 0}
};
private _reason = "completed";
for "_phase" from 0 to 1 do {
    if (!call _valid) exitWith {_reason = "cancelled"};
    _position = [leader _group, _enemy] call VCM_fnc_ContactPosition;
    if (_position isEqualTo [] || {leader _group distance2D _position > 400}) exitWith {_reason = "contactLost"};
    private _support = [_teamA, _teamB] select _phase;
    private _movers = [_teamB, _teamA] select _phase;
    private _reserved = _support apply {getPosATL _x};
    private _destinations = [];
    {
        private _destination = [_x, _position, VCM_BOUNDLENGTH, _reserved] call VCM_fnc_BoundPosition;
        _destinations pushBack _destination;
        if (_destination isNotEqualTo []) then {_reserved pushBack _destination};
    } forEach _movers;
    if (_destinations findIf {_x isEqualTo []} >= 0) exitWith {_reason = "noRoute"};
    // Geometry searches can span scheduler slices; recheck orders and locality before issuing movement.
    if (!call _valid) exitWith {_reason = "cancelled"};
    {[_x] call VCM_fnc_MovementControl; doStop _x} forEach _support;
    private _pulses = [_support, _group, _run, _position, _enemy] call VCM_fnc_BoundSupport;
    if (_pulses == 0) exitWith {_reason = "noSupport"};
    (_state select 6) set [0, (_state select 6 select 0) + _pulses];
    _state set [2, _phase + 1];
    _state set [3, _support];
    _state set [4, _movers];
    _state set [5, _destinations];
    {
        [_x,_key] call VCM_fnc_MovementControl;
        _x suppressFor 0;
        _x doWatch objNull;
    } forEach _movers;
    sleep 0.1;
    if (!call _valid) exitWith {_reason = "cancelled"};
    {[_x,_destinations select _forEachIndex,_run,_key] call VCM_fnc_IssueMove} forEach _movers;
    private _progress = _movers apply {[getPosATL _x,diag_tickTime,0,[]]};
    private _deadline = diag_tickTime + ((VCM_BOUNDSECONDS max 5) min 60);
    private _nextPulse = diag_tickTime + 1;
    private _nextMove = diag_tickTime + 2;
    private _arrived = false;
    waitUntil {
        sleep 0.25;
        if (!call _valid) then {_reason = "cancelled"} else {
            if (diag_tickTime >= _nextMove) then {
                // Native combat can interrupt doMove to engage; keep the moving team's bounded intent current.
                {
                    private _destination = _destinations select _forEachIndex;
                    private _sample = _progress select _forEachIndex;
                    if (diag_tickTime - (_sample select 1) >= VCM_UNSTUCKSECONDS) then {
                        if (_x distance (_sample select 0) < 0.75 && {_x distance _destination > 3} && {VCM_UNSTUCK}) then {
                            private _attempt = 1 + (_sample select 2);
                            _sample set [2,_attempt];
                            if (_attempt > floor VCM_UNSTUCKTRIES) then {_reason = "stuck"} else {
                                _sample set [3,[_x,_destination,_run,_key,_attempt] call VCM_fnc_RecoveryPosition];
                            };
                        };
                        _sample set [0,getPosATL _x];
                        _sample set [1,diag_tickTime];
                    };
                    private _leg = _sample select 3;
                    if (_leg isNotEqualTo [] && {_x distance _leg < 2}) then {_sample set [3,[]]; _leg = []};
                    if (_x distance _destination > 3) then {[_x,if (_leg isEqualTo []) then {_destination} else {_leg},_run,_key] call VCM_fnc_IssueMove};
                } forEach _movers;
                _nextMove = diag_tickTime + 2;
            };
            if (diag_tickTime >= _nextPulse) then {
                _pulses = [_support, _group, _run, _position, _enemy] call VCM_fnc_BoundSupport;
                (_state select 6) set [0, (_state select 6 select 0) + _pulses];
                if (_pulses == 0) then {_reason = "noSupport"};
                _nextPulse = diag_tickTime + 1;
            };
            _arrived = true;
            {if (_x distance (_destinations select _forEachIndex) > 3) then {_arrived = false}} forEach _movers;
        };
        _reason != "completed" || {_arrived} || {diag_tickTime >= _deadline}
    };
    if (_reason != "completed") exitWith {};
    if (!_arrived) exitWith {_reason = "timeout"};
    (_state select 6) set [1, _phase + 1];
};
[_group, _key, _reason] call VCM_fnc_EndFireMove;
