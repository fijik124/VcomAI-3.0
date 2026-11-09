/* Search every mapped room. Coverage requires physical entry and an unobstructed sector scan. */
params ["_group","_key","_building","_entry","_layout","_contact"];
_layout params ["_points","_edges","_roomIds","_rooms","_doors","_notes","_signature"];
private _run = _key select 0;
private _participants = +((_group getVariable ["VCM_Task",[]]) param [2,[]]);
private _deadline = diag_tickTime + VCM_CQBTIME;
private _valid = {
    local _group && {[_group,_run,_key,"clear"] call VCM_fnc_TacticalValid} && {VCM_FULLCLEAR} &&
    {VCM_CQBSECTORS} && {alive _building} && {diag_tickTime < _deadline} &&
    {_participants findIf {!([_x,_group,_run] call VCM_fnc_ActionValid) || {lifeState _x == "INCAPACITATED"} ||
        {!((_x getVariable ["VCM_TaskKey",[]]) isEqualTo _key)}} < 0} &&
    {_signature isEqualTo [getPosWorld _building,vectorDir _building,vectorUp _building,damage _building]}
};
private _searched = [];
private _blocked = [];
private _covered = [];
private _current = -1;
private _progress = [_key,_building,"searching",_current,count _rooms,_searched,_blocked,_covered,{_x select 1 && {(_x select 2) < 2}} count _points,time,""];
private _publish = {
    if (local _group && {((_group getVariable ["VCM_CQBSession",[]]) param [0,[]]) isEqualTo _key}) then {
        _progress set [3,_current]; _group setVariable ["VCM_CQBProgress",_progress,true];
    };
};
call _publish;
private _pending = [];
{_pending pushBack _forEachIndex} forEach _rooms;
private _outside = ((_group getVariable ["VCM_Task",[]]) select 2) - _entry;
{[_x] call VCM_fnc_MovementControl; _x setVariable ["VCM_TaskRole",[_key,"outside"],true]; doStop _x} forEach _outside;
while {_pending isNotEqualTo [] && {call _valid} && {count _searched + count _blocked < floor VCM_CQBROOMS}} do {
    private _lead = _entry select ((count _searched + count _blocked) mod count _entry);
    private _nearest = _pending apply {
        private _room = _x;
        private _score = 1e9;
        {_score = _score min (_lead distance (_points select _x select 0))} forEach (_rooms select _room);
        [_score,_room]
    };
    _nearest sort true;
    _current = _nearest select 0 select 1;
    _pending deleteAt (_pending find _current);
    call _publish;
    [_group,"cqb-room-start",format ["%1 of %2",_current + 1,count _rooms]] call VCM_fnc_DebugTrace;
    private _goals = +(_rooms select _current);
    private _failed = "";
    private _lastFailure = "unobserved-or-unreachable-points";
    private _attempted = [];
    private _roomUntil = (diag_tickTime + VCM_CQBSECONDS) min _deadline;
    {
        private _role = if (_x == _lead) then {"entry"} else {"rear"};
        _x setVariable ["VCM_TaskRole",[_key,_role],true];
        _x setVariable ["VCM_CQBSector",[_building,_current,_contact],true];
        [_x] call VCM_fnc_MovementControl;
        if (_x != _lead) then {doStop _x; _x doWatch (getPosATL _lead vectorAdd [0,0,1])};
    } forEach _entry;
    while {_goals isNotEqualTo [] && {call _valid} && {_failed == ""} && {diag_tickTime < _roomUntil}} do {
        private _candidates = (_goals - _attempted) apply {[(_lead distance (_points select _x select 0)) + 12 * ((_points select _x) param [2,1]),_x]};
        if (_candidates isEqualTo []) exitWith {_failed = _lastFailure};
        _candidates sort true;
        private _goal = _candidates select 0 select 1;
        _attempted pushBack _goal;
        private _stepFailed = false;
        private _route = [_building,_layout,getPosATL _lead,_goal] call VCM_fnc_CQBRoute;
        if (_route isEqualTo []) then {
            private _locked = _doors findIf {_building animationSourcePhase (_x select 1) < 0.65 &&
                {!((_building getVariable [format ["bis_disabled_Door_%1",_x select 0],0]) in [0,false])}};
            // Native building paths can connect stair landings absent from a model's straight-line geometry graph.
            if (_locked < 0) then {_route = [_goal]} else {_stepFailed = true; _lastFailure = "locked-door-or-unmapped-route"};
        };
        if (VCM_Debug) then {
            _lead setVariable ["VCM_DebugCQBRoute",[_key,_current,_route apply {_points select _x select 0}]];
            [_group,"clear",format ["Enter and observe room %1; %2 points remain",_current + 1,count _goals],_points select _goal select 0,_contact] call VCM_fnc_DebugDecision;
        };
        {
            if (!call _valid || {_stepFailed}) exitWith {};
            private _destination = _points select _x select 0;
            if (_lead distance _destination > 1.1) then {
                if (!([_lead,_destination,_group,_key,_building,_doors,_roomUntil] call VCM_fnc_CQBMove)) then {_stepFailed = true};
            };
        } forEach _route;
        if (!_stepFailed && {call _valid} && {([_building,_layout,getPosATL _lead] call VCM_fnc_CQBRoomAt) == _current}) then {
            doStop _lead;
            [_lead] call VCM_fnc_MovementControl;
            private _scanStart = diag_tickTime;
            for "_sector" from 0 to 3 do {
                if (!call _valid || {diag_tickTime >= _roomUntil}) exitWith {};
                _lead doWatch ((_lead getPos [5,getDir _building + 90 * _sector]) vectorAdd [0,0,1]);
                private _until = (_scanStart + VCM_CQBSCAN * (_sector + 1) / 4) min _roomUntil;
                waitUntil {sleep 0.1; !call _valid || {diag_tickTime >= _until}};
            };
            if (call _valid && {diag_tickTime - _scanStart >= VCM_CQBSCAN}) then {
                {
                    private _point = _points select _x select 0;
                    if (_lead distance _point < 9 && {abs ((getPosASL _lead select 2) - (ATLToASL _point select 2)) < 0.8} &&
                        {([_lead,"VIEW",objNull] checkVisibility [eyePos _lead,ATLToASL (_point vectorAdd [0,0,1])]) > 0.2} &&
                        {[eyePos _lead,ATLToASL (_point vectorAdd [0,0,1]),_lead] call VCM_fnc_PhysicalFireLane}) then {_covered pushBackUnique _x};
                } forEach _goals;
                private _remaining = _goals - _covered;
                _goals = _remaining;
                [_outside + (_entry - [_lead]),_contact,objNull] call VCM_fnc_TacticalSupport;
            };
        };
    };
    if (!call _valid) exitWith {};
    if (_goals isEqualTo [] && {_failed == ""}) then {
        _searched pushBack _current;
        [_group,"cqb-room-searched",str (_current + 1)] call VCM_fnc_DebugTrace;
    } else {
        _blocked pushBack [_current,if (_failed == "") then {"room-timeout"} else {_failed}];
        [_group,"cqb-room-blocked",str (_blocked select (count _blocked - 1))] call VCM_fnc_DebugTrace;
    };
    call _publish;
};
private _complete = call _valid && {_pending isEqualTo []} && {_blocked isEqualTo []} && {_notes isEqualTo []};
private _status = if (_complete) then {"searched"} else {"partial"};
private _reason = if (_complete) then {"all-mapped-rooms-searched"} else {
    if (!alive _building) then {"building-destroyed"} else {
        if (diag_tickTime >= _deadline) then {"search-deadline"} else {
            if (!call _valid) then {"cancelled"} else {if (_pending isNotEqualTo []) then {"room-limit"} else {"blocked-or-limited-layout"}}
        }
    }
};
if (_complete) then {
    private _bounds = boundingBoxReal _building;
    private _low = _bounds select 0;
    private _high = _bounds select 1;
    private _remainingContact = ([leader _group] call VCM_fnc_KnownContacts) findIf {
        _x params ["_position","_type","_side","_cost","_target"];
        private _point = _building worldToModel _position;
        !isNull _target && {alive _target} && {[side _group,_side] call BIS_fnc_sideIsEnemy} &&
        {_point select 0 > (_low select 0)} && {_point select 0 < (_high select 0)} &&
        {_point select 1 > (_low select 1)} && {_point select 1 < (_high select 1)} &&
        {_point select 2 > (_low select 2)} && {_point select 2 < (_high select 2)}
    };
    if (_remainingContact >= 0) then {_status = "searched-contact-remains"; _reason = "known-hostile-remains"};
};
if (local _group && {((_group getVariable ["VCM_CQBSession",[]]) param [0,[]]) isEqualTo _key}) then {
    _progress set [2,_status]; _progress set [10,_reason]; call _publish;
};
[_group,"cqb-finish",format ["%1 %2/%3 %4",_status,count _searched,count _rooms,_reason]] call VCM_fnc_DebugTrace;
_complete
