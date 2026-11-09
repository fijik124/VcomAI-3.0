/* Scheduled finite phases: support, movers, destinations, seconds, watch position. */
params ["_group","_kind","_phases","_enemy","_contact"];
if (!([_group] call VCM_fnc_TacticalReady) || {_phases isEqualTo []}) exitWith {false};
private _run = _group getVariable ["VCM_RunId",[]];
private _serial = 1 + (_group getVariable ["VCM_TaskSerial",0]);
private _key = [_run,_serial];
private _units = [];
{_units append (_x select 0); _units append (_x select 1)} forEach _phases;
_units = _units arrayIntersect _units;
if (_units isEqualTo [] || {_units findIf {!([_x,_group,_run] call VCM_fnc_ActionValid)} >= 0}) exitWith {false};
private _state = [_key,_kind,_units,0,0];
_group setVariable ["VCM_TaskSerial",_serial];
_group setVariable ["VCM_Task",_state];
_group setVariable ["VCM_Committed",true,true];
[_group,"task-start",_kind] call VCM_fnc_DebugTrace;
private _why = switch (_kind) do {
    case "clear": {"Remembered hostile contact is inside a building"};
    case "retreat": {"Casualty or suppression threshold requires withdrawal"};
    case "evac": {"A reachable casualty needs recovery toward cover"};
    case "escort": {"Friendly infantry and vehicle can cooperate"};
    case "cooperate": {"Server coordinator assigned this squad a combat role"};
    case "antitank": {"Reserved an armored contact for an eligible launcher"};
    default {"Available support soldiers cover pressured teammates"};
};
[_group,_kind,_why,(_phases select 0 select 2) param [0,[]],_contact] call VCM_fnc_DebugDecision;
[_group,_key] call VCM_fnc_AttackControl;
{_x setVariable ["VCM_TaskKey",_key,true]} forEach _units;
if (_kind in ["retreat","evac"] && {VCM_SMOKECOVER}) then {
    private _smoker = (_phases select 0 select 0) param [0,objNull];
    if (!isNull _smoker) then {[_smoker,_contact,_key] spawn VCM_fnc_SmokeCover};
};
private _valid = {
    [_group,_run,_key,_kind] call VCM_fnc_TacticalValid &&
    {_units findIf {!([_x,_group,_run] call VCM_fnc_ActionValid) || {lifeState _x == "INCAPACITATED"}} < 0}
};
private _reason = "completed";
{
    if (!call _valid) exitWith {_reason = "cancelled"};
    _x params ["_support","_movers","_destinations","_seconds","_watch",["_operation",[]]];
    _state set [3,_forEachIndex + 1];
    if (_operation isNotEqualTo [] && {!([_group,_key,_operation] call VCM_fnc_TaskOperation)}) exitWith {_reason = "operation-failed"};
    if (!call _valid) exitWith {_reason = "cancelled"};
    {
        [_x] call VCM_fnc_MovementControl;
        _x setVariable ["VCM_TaskRole",[_key,"support"],true];
        doStop _x;
        private _watchPoint = _watch;
        private _sector = _x getVariable ["VCM_CQBSector",[]];
        if (_kind == "clear" && {_sector isNotEqualTo []}) then {
            _watchPoint = _x getPos [8,getDir (_sector select 0) + 90 * ((_sector select 1) mod 4)];
        };
        _x doWatch (_watchPoint vectorAdd [0,0,1]);
    } forEach _support;
    if (_kind == "clear" && {VCM_CQBSECTORS}) then {
        private _building = (_group getVariable ["VCM_LastClearPlan",[]]) param [0,objNull];
        {[_x,_building] call VCM_fnc_OpenNearDoors} forEach _movers;
    };
    private _jobs = [];
    {
        [_x,_key] call VCM_fnc_MovementControl;
        _x setVariable ["VCM_TaskRole",[_key,"move"],true];
        _x suppressFor 0;
        _x doWatch objNull;
        _jobs pushBack ([_x,_destinations select _forEachIndex,_seconds,_run,_key,_kind] spawn {
            params ["_unit","_destination","_seconds","_run","_key","_kind"];
            // Regrouping from a native attack subformation settles on the next engine update.
            sleep 0.1;
            private _group = group _unit;
            if (!([_group,_run,_key,_kind] call VCM_fnc_TacticalValid)) exitWith {};
            _unit setVariable ["VCM_LastTaskMove",[_destination,"started",_unit getVariable ["VCM_MoveKey",[]],_unit checkAIFeature "PATH"]];
            private _session = _group getVariable ["VCM_CQBSession",[]];
            private _arrived = if (_kind == "clear" && {_session isNotEqualTo []} && {(_session select 0) isEqualTo _key}) then {
                private _building = _session select 1;
                private _doors = ([_building] call VCM_fnc_CQBDoors);
                [_unit,_destination,_group,_key,_building,_doors,diag_tickTime + _seconds] call VCM_fnc_CQBMove
            } else {
                [_unit,_destination,_seconds,{
                    params ["_unit","_group"];
                    [_group,_run,_key,_kind] call VCM_fnc_TacticalValid
                },_key] call VCM_fnc_MoveTo
            };
            _unit setVariable ["VCM_LastTaskMove",[_destination,_arrived,getPosATL _unit,currentCommand _unit]];
        });
    } forEach _movers;
    private _deadline = diag_tickTime + _seconds + ([0,1] select (_movers isNotEqualTo []));
    private _nextPulse = -1;
    waitUntil {
        sleep 0.25;
        if (call _valid && {diag_tickTime >= _nextPulse}) then {
            _state set [4,(_state select 4) + ([_support,_contact,_enemy] call VCM_fnc_TacticalSupport)];
            _nextPulse = diag_tickTime + 1;
        };
        !call _valid || {diag_tickTime >= _deadline} ||
            {_movers isNotEqualTo [] && {_jobs findIf {!scriptDone _x} < 0}}
    };
    if (!call _valid) exitWith {_reason = "cancelled"};
    private _missed = false;
    {if (_x distance (_destinations select _forEachIndex) > 3) then {_missed = true}} forEach _movers;
    if (_missed) exitWith {_reason = "timeout"};
} forEach _phases;
[_group,_key,_reason] call VCM_fnc_EndTactical;
_reason == "completed"
