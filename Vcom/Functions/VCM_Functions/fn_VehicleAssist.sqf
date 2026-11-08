/* Server-issued cross-owner escort. Each machine controls only its own vehicle and crew. */
if (!(isServer && {!isRemoteExecuted}) && {!isRemoteExecuted || {remoteExecutedOwner != 2}}) exitWith {};
params ["_group","_infantry","_vehicle","_stage","_point","_key","_expiry","_infantryOwner"];
// Public lease updates and remote calls can arrive on different network queues.
private _syncUntil = diag_tickTime + 2;
waitUntil {sleep 0.05;
    (((_vehicle getVariable ["VCM_InfantryPartner",[]]) param [1,[]]) isEqualTo _key &&
    {((_infantry getVariable ["VCM_CoordMission",[]]) param [0,[]]) isEqualTo _key}) ||
    {diag_tickTime >= _syncUntil} || {!local _group}
};
private _driver = driver _vehicle;
private _valid = {
    local _group && {local _vehicle} && {local _driver} && {alive _driver} && {canMove _vehicle} &&
    {driver _vehicle == _driver} && {VCM_CROSSOWNER_ESCORT} && {VCM_COMBINEDARMS} && {time < _expiry} &&
    {[_group] call VCM_fnc_GroupEnabled} && {!(_group getVariable ["VCM_NOFLANK",false])} &&
    {((_infantry getVariable ["VCM_CoordMission",[]]) param [3,-1]) == _infantryOwner} &&
    {!isNull _infantry} && {!(_infantry getVariable ["Vcm_Disable",false])} &&
    {side _infantry in VCM_SIDEENABLED} &&
    {(units _group + units _infantry) findIf {[_x] call VCM_fnc_HumanControlled} < 0} &&
    {(waypoints _group + waypoints _infantry) findIf {(_x select 1) > 0} < 0} &&
    {((_vehicle getVariable ["VCM_InfantryPartner",[]]) param [1,[]]) isEqualTo _key} &&
    {((_infantry getVariable ["VCM_CoordMission",[]]) param [0,[]]) isEqualTo _key}
};
if (!call _valid) exitWith {
    [_group,"escort-rejected",format ["vehicle local=%1 driver local=%2 group enabled=%3 owner=%4 expected=%5 lease=%6 infantryLease=%7 now=%8 expiry=%9",local _vehicle,local _driver,[_group] call VCM_fnc_GroupEnabled,groupOwner _infantry,_infantryOwner,_vehicle getVariable ["VCM_InfantryPartner",[]],_infantry getVariable ["VCM_CoordMission",[]],time,_expiry]] call VCM_fnc_DebugTrace;
    [_group,_key] call VCM_fnc_CoordRelease
};
_group setVariable ["VCM_LastVehicleAssist",[_key,_infantry,clientOwner,_stage],true];
private _moving = false;
while {call _valid} do {
    private _clear = [_vehicle,18] call VCM_fnc_VehicleFrontClear;
    if (_clear && {_vehicle distance2D _stage > 6}) then {
        if (!_moving) then {_driver doMove _stage; _moving = true};
    } else {
        if (_moving) then {doStop _driver; _moving = false};
    };
    private _gunner = gunner _vehicle;
    if (!isNull _gunner && {local _gunner} && {!([_gunner] call VCM_fnc_HumanControlled)}) then {_gunner doWatch (_point vectorAdd [0,0,1])};
    sleep 0.5;
};
if (local _driver && {!([_driver] call VCM_fnc_HumanControlled)} &&
    {(waypoints _group) findIf {(_x select 1) > 0} < 0} &&
    {((_vehicle getVariable ["VCM_InfantryPartner",[]]) param [1,[]]) isEqualTo _key}) then {
    doStop _driver;
    if (local gunner _vehicle) then {gunner _vehicle doWatch objNull};
};
[_group,_key] call VCM_fnc_CoordRelease;
