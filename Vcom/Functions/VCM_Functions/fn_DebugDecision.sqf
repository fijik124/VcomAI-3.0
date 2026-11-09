/* Record a controller's actual decision. This is diagnostic state, never an AI order. */
params ["_group","_action","_reason",["_goal",[]],["_contact",[]]];
if (!VCM_Debug || {!local _group}) exitWith {};
private _decision = [_action,_reason,_goal,_contact];
private _old = _group getVariable ["VCM_DebugDecision",[]];
if ((_old select [1,4]) isNotEqualTo _decision) then {
    _group setVariable ["VCM_DebugDecision",[time] + _decision];
    [_group,"decision",_action + ": " + _reason] call VCM_fnc_DebugTrace;
};
