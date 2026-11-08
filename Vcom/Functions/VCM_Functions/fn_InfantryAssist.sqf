if (!(isServer && {!isRemoteExecuted}) && {!isRemoteExecuted || {remoteExecutedOwner != 2}}) exitWith {};
params ["_group","_crew","_vehicle","_stage","_enemy","_contact","_key","_expiry","_crewOwner"];
if (!local _group || {!VCM_CROSSOWNER_ESCORT} || {time >= _expiry}) exitWith {};
private _syncUntil = diag_tickTime + 2;
waitUntil {sleep 0.05;
    (((_group getVariable ["VCM_CoordMission",[]]) param [0,[]]) isEqualTo _key &&
    {((_vehicle getVariable ["VCM_InfantryPartner",[]]) param [1,[]]) isEqualTo _key}) ||
    {diag_tickTime >= _syncUntil} || {!local _group}
};
private _leaseValid = {
    local _group && {VCM_CROSSOWNER_ESCORT} && {VCM_COMBINEDARMS} && {time < _expiry} &&
    {alive _vehicle} && {canMove _vehicle} &&
    {((_crew getVariable ["VCM_CoordMission",[]]) param [0,[]]) isEqualTo _key} &&
    {((_crew getVariable ["VCM_CoordMission",[]]) param [3,-1]) == _crewOwner} &&
    {(units _crew) findIf {[_x] call VCM_fnc_HumanControlled} < 0} &&
    {(waypoints _crew) findIf {(_x select 1) > 0} < 0} &&
    {((_group getVariable ["VCM_CoordMission",[]]) param [0,[]]) isEqualTo _key} &&
    {((_vehicle getVariable ["VCM_InfantryPartner",[]]) param [1,[]]) isEqualTo _key}
};
if (!call _leaseValid) exitWith {[_group,"escort-rejected","infantry lease invalid at receiver"] call VCM_fnc_DebugTrace; [_group,_key] call VCM_fnc_CoordRelease};
if (!(_group in VcmAI_ActiveList)) then {_group call VCM_fnc_SquadExc};
if (VCM_CARGOCHNG && {abs speed _vehicle < 3} && {_vehicle distance2D _contact > 100} && {getPosATL _vehicle select 2 < 2}) then {
    {
        if (local _x && {vehicle _x == _vehicle} && {_x != driver _vehicle} && {_x != gunner _vehicle} &&
            {!([_x] call VCM_fnc_HumanControlled)}) then {unassignVehicle _x; [_x] orderGetIn false; doGetOut _x};
    } forEach units _group;
};
private _deadline = diag_tickTime + 10;
waitUntil {sleep 0.25; count ([_group] call VCM_fnc_TacticalUnits) >= 2 || {diag_tickTime > _deadline} || {!call _leaseValid}};
private _units = ([_group] call VCM_fnc_TacticalUnits) select [0,8];
if (!call _leaseValid || {count _units < 2}) exitWith {[_group,_key] call VCM_fnc_CoordRelease};
private _support = [_units select 0];
private _movers = _units - _support;
private _positions = [];
private _screen = _stage getPos [20,_contact getDir _stage];
{
    private _goal = (_screen getPos [3 * _forEachIndex,(_contact getDir _stage) + 90]) findEmptyPosition [0,3,typeOf _x];
    if (_goal isNotEqualTo [] && {_x distance2D _goal < 90} && {!surfaceIsWater _goal}) then {_positions pushBack _goal};
} forEach _movers;
if (count _positions == count _movers) then {
    _group setVariable ["VCM_LastEscort",[_key,_vehicle,clientOwner,_crewOwner],true];
    private _job = [_group,"escort",[[_support,_movers,_positions,25,_contact]],_enemy,_contact] spawn VCM_fnc_RunTactical;
    waitUntil {sleep 0.25; scriptDone _job || {!call _leaseValid}};
    if (!scriptDone _job) then {
        private _taskKey = (_group getVariable ["VCM_Task",[]]) param [0,[]];
        if (_taskKey isNotEqualTo []) then {[_group,_taskKey,"escort-lease-ended"] call VCM_fnc_EndTactical};
    };
};
[_group,_key] call VCM_fnc_CoordRelease;
