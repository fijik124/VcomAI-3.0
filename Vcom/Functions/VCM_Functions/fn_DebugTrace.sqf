/* Bounded event history; no histories or RPT traffic while debugging is disabled. */
params ["_group","_event",["_detail",""]];
if (!VCM_Debug || {isNull _group}) exitWith {};
private _history = _group getVariable ["VCM_DebugHistory",[]];
_history pushBack [time,_event,_detail];
private _limit = floor ((VCM_DEBUGHISTORY max 5) min 100);
if (count _history > _limit) then {_history deleteRange [0,count _history - _limit]};
_group setVariable ["VCM_DebugHistory",_history];
private _counters = _group getVariable ["VCM_DebugCounters",createHashMap];
_counters set [_event,1 + (_counters getOrDefault [_event,0])];
_group setVariable ["VCM_DebugCounters",_counters];
diag_log format ["VCM_DEBUG: owner=%1 group=%2 run=%3 event=%4 detail=%5",clientOwner,groupId _group,
    _group getVariable ["VCM_RunId",[]],_event,_detail];
