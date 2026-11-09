/* Native building geometry and complete room-search acceptance. */
VCM_ADVANCEDMOVEMENT = false;
VCM_FIREMOVEMENT = false;
VCM_StealVeh = false;
VCM_MULTISQUAD = false;
VCM_ARTYENABLE = false;
VCM_Debug = true;
{
    private _building = createVehicle [_x,[9000 + 100 * _forEachIndex,11000,0],[],0,"CAN_COLLIDE"];
    sleep 0.1;
    private _started = diag_tickTime;
    private _layout = [_building] call VCM_fnc_CQBLayout;
    _layout params ["_points","_edges","_roomIds","_rooms","_doors","_notes"];
    diag_log format ["VCM_CQB_LAYOUT: type=%1 nodes=%2 rooms=%3 doors=%4 notes=%5 milliseconds=%6",typeOf _building,count _points,_rooms apply {count _x},_doors,_notes,1000 * (diag_tickTime - _started)];
    [count _points > count (_building buildingPos -1),typeOf _building + ": geometry samples expand native building positions"] call _assert;
    [count _rooms >= 2,typeOf _building + ": physical layout separates search rooms"] call _assert;
    [_doors isNotEqualTo [],typeOf _building + ": configured doors are discovered"] call _assert;
    [_layout isEqualTo ([_building] call VCM_fnc_CQBLayout),typeOf _building + ": unchanged layout reuses cached geometry"] call _assert;
    deleteVehicle _building;
} forEach ["Land_i_House_Small_01_V1_F","Land_i_House_Big_01_V1_F","Land_i_Barracks_V1_F"];
[true,"native CQB geometry inspection completed"] call _assert;

private _group = createGroup [west,true];
_group setVariable ["VCM_Skilldisable",true];
_group setVariable ["VCM_NOAUTOTACTICS",true];
private _actors = [];
for "_i" from 0 to 3 do {
    private _actor = _group createUnit ["B_Soldier_F",[10000,11000 + 5 * _i,0],[],0,"NONE"];
    _actor allowDamage false;
    _actors pushBack _actor;
};
_group setCombatMode "GREEN";
_group setBehaviour "COMBAT";
_group call VCM_fnc_SquadExc;
private _building = createVehicle ["Land_i_House_Small_01_V1_F",[10025,11000,0],[],0,"CAN_COLLIDE"];
private _opfor = createGroup [east,true];
_opfor setVariable ["Vcm_Disable",true];
private _enemy = _opfor createUnit ["O_Soldier_F",(_building buildingPos -1) select 0,[],0,"NONE"];
_enemy disableAI "ALL";
_enemy allowDamage false;
_group reveal [_enemy,4];
private _layout = [_building] call VCM_fnc_CQBLayout;
private _waitUntil = diag_tickTime + 6;
waitUntil {sleep 0.1; count ([_group] call VCM_fnc_TacticalUnits) >= 4 &&
    {([leader _group,_enemy] call VCM_fnc_ContactPosition) isNotEqualTo []} || {diag_tickTime > _waitUntil}};
private _plan = [_group,_enemy] call VCM_fnc_ClearBuildingPlan;
[_plan isNotEqualTo [] && {(_plan param [6,[]]) isNotEqualTo []},"full clearing plan contains its physical room graph"] call _assert;
private _features = _actors apply {private _actor = _x; ["TARGET","AUTOTARGET","AUTOCOMBAT","FSM","PATH"] apply {_actor checkAIFeature _x}};
private _job = [_group,_enemy] spawn VCM_fnc_ClearBuilding;
private _startUntil = diag_tickTime + 3;
waitUntil {sleep 0.1; _group getVariable ["VCM_Task",[]] isNotEqualTo [] || {scriptDone _job} || {diag_tickTime > _startUntil}};
// The report starts the search; losing that contact must not abandon the remaining rooms.
deleteVehicle _enemy;
private _deadline = diag_tickTime + 200;
private _sawRoute = false;
waitUntil {
    sleep 1;
    private _snapshot = _group getVariable ["VCM_DebugState",[]];
    if ((_snapshot param [3,[]]) isNotEqualTo []) then {_sawRoute = true};
    if ((round diag_tickTime) mod 5 == 0) then {diag_log format ["VCM_CQB_SEARCH: progress=%1 attack=%2 actors=%3",_group getVariable ["VCM_CQBProgress",[]],attackEnabled _group,_actors apply {[getPosATL _x,currentCommand _x,_x checkAIFeature "TARGET",_x checkAIFeature "FSM",_x getVariable ["VCM_MovementControl",[]]]}]};
    scriptDone _job || {diag_tickTime > _deadline}
};
private _progress = _group getVariable ["VCM_CQBProgress",[]];
diag_log format ["VCM_CQB_FINISHED: %1",_progress];
_group setVariable ["VCM_NextDebug",-1]; [_group] call VCM_fnc_DebugPublish;
private _debug = _group getVariable ["VCM_DebugState",[]];
[_sawRoute,"debugger exposes an active entry soldier's actual planned CQB route"] call _assert;
[count (_debug param [4,[]]) == count (_layout select 3) && {(_debug select 5) isNotEqualTo []},"debugger publishes physical room coverage and live configured door states"] call _assert;
[scriptDone _job && {_progress param [2,""] == "searched"},"native entry team completes the entire mapped building search"] call _assert;
[count (_progress param [5,[]]) == count (_layout select 3) && {_progress param [6,[]] isEqualTo []},"every mapped room receives a completed search record"] call _assert;
[_group getVariable ["VCM_CQBSession",[]] isEqualTo [] && {_actors findIf {_x getVariable ["VCM_TaskKey",[]] isNotEqualTo []} < 0},"full clearing releases group and per-unit ownership tags"] call _assert;
private _restored = true;
{private _actor = _x; if ((["TARGET","AUTOTARGET","AUTOCOMBAT","FSM","PATH"] apply {_actor checkAIFeature _x}) isNotEqualTo (_features select _forEachIndex)) then {_restored = false}} forEach _actors;
[_restored,"room search restores native targeting behavior and leaves pathfinding enabled"] call _assert;
_group setVariable ["Vcm_Disable",true];
sleep 0.5;
{deleteVehicle _x} forEach (_actors + [_building,_enemy]);
deleteGroup _group;
deleteGroup _opfor;
[] call compile preprocessFileLineNumbers "cqb-control.sqf";
