params ["_group"];
if (!VCM_Debug || {!local _group} || {diag_tickTime < (_group getVariable ["VCM_NextDebug",-1])}) exitWith {};
_group setVariable ["VCM_NextDebug",diag_tickTime + VCM_DEBUGINTERVAL];
private _task = _group getVariable ["VCM_Task",[]];
private _bound = _group getVariable ["VCM_BoundState",[]];
private _kind = _task param [1,""];
private _phase = _task param [3,0];
if (_bound isNotEqualTo []) then {
    _kind = "bound"; _phase = _bound select 2;
    {
        private _role = [_bound select 0,if (_x in (_bound select 4)) then {"move"} else {"support"}];
        if (_role isNotEqualTo (_x getVariable ["VCM_DebugBoundRole",[]])) then {_x setVariable ["VCM_DebugBoundRole",_role,true]};
    } forEach (_bound select 1);
};
private _history = _group getVariable ["VCM_DebugHistory",[]];
_history = _history select [(count _history - 5) max 0,5];
private _counters = _group getVariable ["VCM_DebugCounters",createHashMap];
_group setVariable ["VCM_DebugInfo",[clientOwner,diag_fps,_kind,_phase,
    _group getVariable ["VCM_LastTask",[]],_group getVariable ["VCM_LastPlanMS",0],
    _group getVariable ["VCM_PlanInterval",2],_history,
    (keys _counters) apply {[_x,_counters get _x]},time],true];
_group setVariable ["VCM_DebugState",[_group] call VCM_fnc_DebugState,true];
