/* Server-only report distribution. Deliberately absent from CfgRemoteExec. */
if (!isServer || {!Vcm_ActivateAI} || {!VCM_RECON}) exitWith {false};
params [["_source",grpNull,[grpNull]],["_reports",[],[[]]],["_identity",objNull,[objNull]]];
if (isNull _source || {isPlayer leader _source} || {_source getVariable ["Vcm_Disable",false]} ||
    {count _reports > 4} || {_reports isEqualTo []} || {!(side _source in VCM_SIDEENABLED)} ||
    {(assignedItems leader _source) findIf {_x isKindOf ["ItemRadio",configFile >> "CfgWeapons"]} < 0}) exitWith {false};
if (_reports findIf {
    !(_x isEqualType []) || {count _x != 2} || {!((_x select 0) isEqualType objNull)} ||
    {isNull (_x select 0)} || {!alive (_x select 0)} ||
    {!([side _source,side group (_x select 0)] call BIS_fnc_sideIsEnemy)} ||
    {!((_x select 1) isEqualType [])} || {count (_x select 1) != 3} ||
    {(_x select 1) findIf {!(_x isEqualType 0) || {!finite _x}} >= 0} ||
    {leader _source distance2D (_x select 1) > 5000}
} >= 0) exitWith {false};
if (time < (_source getVariable ["VCM_ServerReconAfter",-1])) exitWith {false};
_source setVariable ["VCM_ServerReconAfter",time + VCM_RECONREPORT];
private _recipients = allGroups select {
    _x != _source && {alive leader _x} && {!(isPlayer leader _x)} && {!(_x getVariable ["Vcm_Disable",false])} &&
    {side _x in VCM_SIDEENABLED} && {[side _source,side _x] call BIS_fnc_sideIsFriendly} &&
    {leader _x distance2D leader _source <= VCM_REPORTRANGE} &&
    {(assignedItems leader _x) findIf {_x isKindOf ["ItemRadio",configFile >> "CfgWeapons"]} >= 0}
};
_recipients = [_recipients,[],{leader _x distance2D leader _source},"ASCEND"] call BIS_fnc_sortBy;
{
    private _group = _x;
    private _known = (_group getVariable ["VCM_ScoutReports",[]]) select {time - (_x select 2) < 30};
    {
        _x params ["_target","_position"];
        _known = _known select {_x select 0 != _target};
        _known pushBack [_target,+_position,time,side group _target,typeOf _target];
    } forEach _reports;
    _group setVariable ["VCM_ScoutReports",_known select [(count _known - 8) max 0,8],true];
} forEach (_recipients select [0,3]);
_source setVariable ["VCM_LastReconReport",[time,_reports,count (_recipients select [0,3])],true];
true
