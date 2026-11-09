/* Author: Genesis. Clear remembered contact positions without piling the whole squad onto one point. */
params ["_group", "_enemy"];
// FSM actions and event handlers cannot suspend. Keep the public entry point safe in either environment.
if (!canSuspend) exitWith {[_group,_enemy] spawn VCM_fnc_ClearBuilding; false};
private _plan = [_group,_enemy] call VCM_fnc_ClearBuildingPlan;
if (_plan isEqualTo []) exitWith {false};
_plan params ["_building","_support","_entry","_entrance","_phases","_contact"];
_group setVariable ["VCM_ClearAfter",diag_tickTime + 90];
_group setVariable ["VCM_LastClearPlan",[_building,_support,_entry,_entrance],true];
private _sessionKey = [];
if ((_plan param [6,[]]) isNotEqualTo []) then {
    _sessionKey = [_group getVariable ["VCM_RunId",[]],1 + (_group getVariable ["VCM_TaskSerial",0])];
    _group setVariable ["VCM_CQBSession",[_sessionKey,_building],true];
    private _layout = _plan select 6;
    _group setVariable ["VCM_CQBProgress",[_sessionKey,_building,"searching",-1,count (_layout select 3),[],[],[],
        {_x select 1 && {(_x select 2) < 2}} count (_layout select 0),time,"approaching"],true];
};
private _result = [_group,"clear",_phases,_enemy,_contact] call VCM_fnc_RunTactical;
if (_sessionKey isNotEqualTo []) then {[_group,_sessionKey,if (_result) then {"completed"} else {"cancelled"}] call VCM_fnc_CQBRelease};
_result
