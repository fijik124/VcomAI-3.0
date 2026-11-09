private _group = _this;
if (!([_group] call VCM_fnc_GroupEnabled) || {_group in VcmAI_ActiveList}) exitWith {};
[_group] call VCM_fnc_RestoreCombat;
[_group] call VCM_fnc_EvacRelease;
private _cqb = _group getVariable ["VCM_CQBSession",[]];
if (_cqb isNotEqualTo []) then {[_group,_cqb select 0,"owner-changed"] call VCM_fnc_CQBRelease};
_group setVariable ["VCM_Committed",false,true];
_group setVariable ["VCM_ATShooter",nil];
private _mission = _group getVariable ["VCM_CoordMission",[]];
if (_mission isNotEqualTo [] && {time >= (_mission select 2) || {_mission select 3 != clientOwner}}) then {
    [_group,_mission select 0] call VCM_fnc_CoordRelease;
};
VCM_RunSerial = VCM_RunSerial + 1;
private _run = [clientOwner, VCM_RunSerial];
_group setVariable ["VCM_RunId", _run];
[_group,"controller ready","Local owner acquired the group; prior reservations were released"] call VCM_fnc_DebugDecision;
_group setVariable ["VCM_BoundUnits", []];
_group setVariable ["VCM_PeakStrength",(_group getVariable ["VCM_PeakStrength",0]) max ({alive _x} count units _group),true];
VcmAI_ActiveList pushBackUnique _group;
private _fsm = _group execFSM "Vcom\FSMS\fn_SQUADBEH.fsm";
[_group, _run, _fsm] spawn {
    params ["_group", "_run", "_fsm"];
    private _units = [];
    private _nextBind = diag_tickTime + 1;
    private _nextUtility = diag_tickTime + 1;
    _group setVariable ["VCM_NextTactic",diag_tickTime + 2];
    waitUntil {
        sleep 0.25;
        if ([_group] call VCM_fnc_GroupEnabled && {_run isEqualTo (_group getVariable ["VCM_RunId", []])}) then {
            if (diag_tickTime >= _nextBind) then {[_group] call VCM_fnc_BindUnits; _nextBind = diag_tickTime + 1};
            {[_x, _run] call VCM_fnc_SafetyTick} forEach (_group getVariable ["VCM_BoundUnits", []]);
            if (diag_tickTime >= _nextUtility) then {
                [_group] call VCM_fnc_ConvoyTick;
                private _mission = _group getVariable ["VCM_CoordMission",[]];
                if (_mission isNotEqualTo [] && {time >= (_mission select 2)}) then {[_group,_mission select 0] call VCM_fnc_CoordRelease};
                _nextUtility = diag_tickTime + 1;
            };
            if (diag_tickTime >= (_group getVariable ["VCM_NextTactic",-1])) then {
                private _interval = [_group] call VCM_fnc_PlanBudget;
                if (_interval >= 0) then {
                    private _started = diag_tickTime;
                    [_group] call VCM_fnc_TacticalTick;
                    private _elapsed = 1000 * (diag_tickTime - _started);
                    _group setVariable ["VCM_LastPlanMS",_elapsed];
                    private _budget = missionNamespace getVariable ["VCM_FrameBudget",[diag_frameNo,0]];
                    if (_budget select 0 != diag_frameNo) then {_budget = [diag_frameNo,0]; VCM_FrameBudget = _budget};
                    _budget set [1,(_budget select 1) + _elapsed];
                    _group setVariable ["VCM_NextTactic",diag_tickTime + _interval];
                } else {_group setVariable ["VCM_NextTactic",diag_tickTime + 0.25]};
            };
            [_group] call VCM_fnc_DebugPublish;
        };
        if (_run isEqualTo (_group getVariable ["VCM_RunId", []])) then {_units = +(_group getVariable ["VCM_BoundUnits", []])};
        completedFSM _fsm || {!([_group] call VCM_fnc_GroupEnabled)} ||
        {!(_run isEqualTo (_group getVariable ["VCM_RunId", []]))}
    };
    [_group, _run, _units] call VCM_fnc_CleanupGroup;
};
