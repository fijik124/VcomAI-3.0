/* Only the server dispatches a responder; the current owner revalidates its mission orders. */
if (!(isServer && {!isRemoteExecuted}) && {!isRemoteExecuted || {remoteExecutedOwner != 2}}) exitWith {false};
params ["_group","_position","_request"];
if (!([_group] call VCM_fnc_GroupEnabled) || {_group getVariable ["VCM_NORESCUE",false]} ||
    {_group getVariable ["VCM_NOFLANK",false]} || {_group getVariable ["VCM_MOVE2SUP",false]} ||
    {_group getVariable ["VCM_Committed",false]} || {(waypoints _group) findIf {(_x select 1) > 0} >= 0} ||
    {(assignedItems leader _group) findIf {_x isKindOf ["ItemRadio",configFile >> "CfgWeapons"]} < 0}) exitWith {false};
if (!(_group in VcmAI_ActiveList)) then {_group call VCM_fnc_SquadExc};
private _run = _group getVariable ["VCM_RunId",[]];
_group setVariable ["VCM_MOVE2SUP",true,true];
private _waypoint = [_group,_position] call VCM_fnc_AddWaypoint;
private _name = waypointName _waypoint;
_group setCurrentWaypoint _waypoint;
_group setVariable ["VCM_LastSupport",[_request,_position,clientOwner],true];
[_group,_run,_name,_position] spawn {
    params ["_group","_run","_name","_position"];
    private _deadline = diag_tickTime + 180;
    waitUntil {
        sleep 1;
        !([_group] call VCM_fnc_GroupEnabled) || {!(_run isEqualTo (_group getVariable ["VCM_RunId",[]]))} ||
        {diag_tickTime >= _deadline} || {leader _group distance2D _position < 30} ||
        {(waypoints _group) findIf {(_x select 1) > 0 && {waypointName _x != _name}} >= 0}
    };
    if (_run isEqualTo (_group getVariable ["VCM_RunId",[]])) then {
        [_group,[_name]] call VCM_fnc_ClearWaypoints;
        _group setVariable ["VCM_MOVE2SUP",false,true];
    };
};
true
