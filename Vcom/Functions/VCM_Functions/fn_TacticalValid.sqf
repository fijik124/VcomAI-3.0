params ["_group","_run","_key","_kind"];
private _setting = switch (_kind) do {
    case "retreat": {"VCM_TACTICALRETREAT"};
    case "clear": {"VCM_BUILDINGCLEARING"};
    case "escort": {"VCM_COMBINEDARMS"};
    case "cooperate": {"VCM_MULTISQUAD"};
    case "antitank": {"VCM_ATCOORD"};
    case "evac": {"VCM_CASEVAC"};
    default {"VCM_REACTIVESUPPRESSION"};
};
[_group] call VCM_fnc_GroupEnabled && {_run isEqualTo (_group getVariable ["VCM_RunId",[]])} &&
{missionNamespace getVariable [_setting,false]} && {!(_group getVariable ["VCM_NOFLANK",false])} &&
{_kind != "clear" || {_group getVariable ["VCM_CQBSession",[]] isEqualTo []} || {VCM_FULLCLEAR && {VCM_CQBSECTORS} &&
    {alive ((_group getVariable ["VCM_CQBSession",[]]) param [1,objNull])}}} &&
{!(_kind in ["cooperate","antitank"]) || {
    private _mission = _group getVariable ["VCM_CoordMission",[]];
    _mission isNotEqualTo [] && {time < (_mission select 2)} && {_mission select 3 == clientOwner}
}} &&
{_kind != "evac" || {VCM_MEDICALACTIVE || {VCM_ACECASEVAC}}} &&
{((_group getVariable ["VCM_Task",[]]) param [0,[]]) isEqualTo _key} &&
{(waypoints _group) findIf {(_x select 1) > 0} < 0} && {(units _group) findIf {[_x] call VCM_fnc_HumanControlled} < 0}
