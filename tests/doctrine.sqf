/* Native acceptance for doctrine, command points, recon, flank response, danger memory and night equipment. */
diag_log format ["VCM_DOCTRINE_ENV: engine=%1 worldSize=%2",productVersion,worldSize];
VCM_ADVANCEDMOVEMENT = false; VCM_FIREMOVEMENT = false; VCM_BUILDINGCLEARING = false;
VCM_ARTYENABLE = false; VCM_StealVeh = false; VCM_COMBINEDARMS = false;
VCM_MULTISQUAD = false; VCM_CASEVAC = false; VCM_COUNTERFLANK = false;
VCM_POINTSCAN = 5; VCM_POINTINTERVAL = 5;
private _group = createGroup [west,true];
_group setVariable ["VCM_Skilldisable",true];
_group setVariable ["VCM_NOAUTOTACTICS",true];
private _actors = [];
for "_i" from 0 to 3 do {
    private _unit = _group createUnit ["B_Soldier_F",[7000,7000 + 5 * _i,0],[],0,"NONE"];
    _unit allowDamage false; _actors pushBack _unit;
};
private _unit = leader _group;
_group setCombatMode "YELLOW";
_group call VCM_fnc_SquadExc;
sleep 1.5;
_group setVariable ["VCM_NextTactic",1e9];
private _run = _group getVariable ["VCM_RunId",[]];
private _enemyGroup = createGroup [east,true];
_enemyGroup setVariable ["Vcm_Disable",true];
private _enemy = _enemyGroup createUnit ["O_Soldier_F",[7000,7200,0],[],0,"NONE"];
_enemy disableAI "ALL"; _enemy allowDamage false;
private _flanker = _enemyGroup createUnit ["O_Soldier_F",[7200,7000,0],[],0,"NONE"];
_flanker disableAI "ALL"; _flanker allowDamage false;
private _order = {
    params ["_action",["_kind",""],["_position",[7000,7000,0]],["_radius",12]];
    private _accepted = [objNull,_action,_kind,[_group],_position,0,_radius] call VCM_fnc_CommanderOrder;
    [_group] call VCM_fnc_CommandTick;
    _group setVariable ["VCM_NextTactic",1e9];
    _accepted
};
private _await = {
    params ["_condition",["_seconds",15]];
    private _deadline = diag_tickTime + _seconds;
    waitUntil {sleep 0.1; call _condition || {diag_tickTime >= _deadline}};
    call _condition
};
[["point","unknown"] call _order isEqualTo false,"commander rejects unknown point types"] call _assert;
[!([objNull,"doctrine","assault",[_group],[7000,7000,0],0,10] call VCM_fnc_CommanderRequest),
    "remote commander entry rejects null identity even with native sender zero"] call _assert;
[!isClass (missionConfigFile >> "CfgRemoteExec" >> "Functions" >> "VCM_fnc_CommanderOrder") &&
    {!isClass (configFile >> "CfgRemoteExec" >> "Functions" >> "VCM_fnc_CommanderOrder")} &&
    {!isClass (missionConfigFile >> "CfgRemoteExec" >> "Functions" >> "VCM_fnc_ReconPublish")} &&
    {!isClass (configFile >> "CfgRemoteExec" >> "Functions" >> "VCM_fnc_ReconPublish")},
    "server-local order and report implementations are absent from RPC whitelists"] call _assert;
[!([objNull,"point","recon",[_group],["bad",0,0],0,10] call VCM_fnc_CommanderOrder),"commander rejects malformed coordinates"] call _assert;
VCM_DANGERMAX = 4;
for "_i" from 0 to 8 do {[_group,[6000 + _i * 40,6000,0],1,"incoming fire"] call VCM_fnc_DangerRemember};
[count (_group getVariable ["VCM_DangerMemory",[]]) == 4,"danger memory retains a bounded number of records"] call _assert;
[_group,[6320,6000,0],2,"incoming fire"] call VCM_fnc_DangerRemember;
[count (_group getVariable ["VCM_DangerMemory",[]]) == 4,"nearby danger observations merge"] call _assert;
[([_group,[6320,6000,0]] call VCM_fnc_DangerPenalty) > 0 && {[_group,[5000,5000,0]] call VCM_fnc_DangerPenalty == 0},
    "danger penalties apply only near remembered areas"] call _assert;
["resetDanger","",[6320,6000,0],20] call _order;
[_group] call VCM_fnc_CommandTick;
[[ _group,[6320,6000,0]] call VCM_fnc_DangerPenalty == 0,"point-scoped danger reset removes nearby memory"] call _assert;
[["point","danger",[7030,7000,0],20] call _order,"Zeus data path creates an assigned danger marker"] call _assert;
[([_group,[7030,7000,0]] call VCM_fnc_DangerPenalty) >= 100,"explicit danger area influences destination scoring"] call _assert;
["resetPoint","",[7030,7000,0]] call _order;
[[ _group,[7030,7000,0]] call VCM_fnc_DangerPenalty == 0,"removing the danger point removes its planning influence"] call _assert;
private _priorModes = _actors apply {unitCombatMode _x};
[["doctrine","recon"] call _order,"server applies a reconnaissance doctrine"] call _assert;
_group setVariable ["VCM_NOAUTOTACTICS",false];
[_group] call VCM_fnc_CommandTick;
[[_group] call VCM_fnc_Doctrine == "recon" && {!([_group] call VCM_fnc_Autonomy)},"recon doctrine blocks competing offensive planners"] call _assert;
[_actors findIf {unitCombatMode _x != "GREEN"} < 0,"recon tightens eligible soldiers to return fire"] call _assert;
[_group getVariable ["VCM_LastIncoming",-100] < time - 15,"quiet recon does not invent enemy detection"] call _assert;
_group setVariable ["VCM_LastIncoming",time];
[_group] call VCM_fnc_CommandTick;
[(_actors apply {unitCombatMode _x}) isEqualTo _priorModes,"incoming fire releases only VCOM's recon engagement restriction"] call _assert;
_group setVariable ["VCM_NOAUTOTACTICS",true];
_group setVariable ["VCM_LastIncoming",-100];
["resetGroup"] call _order; [_group] call VCM_fnc_CommandTick;
_group setCombatMode "GREEN";
diag_log format ["VCM_COMMAND_RESET: profile=%1 memory=%2 reset=%3 applied=%4 revision=%5",
    [_group] call VCM_fnc_Doctrine,_group getVariable ["VCM_DangerMemory",[]],_group getVariable ["VCM_MemoryReset",[]],
    _group getVariable ["VCM_AppliedMemoryReset",-1],_group getVariable ["VCM_CommandRevision",-1]];
[[ _group] call VCM_fnc_Doctrine == "default" && {_group getVariable ["VCM_DangerMemory",[]] isEqualTo []},"squad reset clears doctrine and remembered danger"] call _assert;
[["point","recon",[6975,7000,0],10] call _order,"observation point is assigned without adding waypoints"] call _assert;
[_group] call VCM_fnc_CommandTick;
_group setVariable ["VCM_ObjectiveAfter",-1];
private _plan = [_group] call VCM_fnc_ObjectivePlan;
[_plan isNotEqualTo [] && {(_plan select 0 select 1) == "recon"},"recon point builds physical separated observation positions"] call _assert;
if (_plan isNotEqualTo []) then {
    private _start = _actors apply {getPosATL _x};
    private _job = [_group,_plan] spawn VCM_fnc_ObjectiveTask;
    [{scriptDone _job},110] call _await;
    private _last = _group getVariable ["VCM_LastTask",[]];
    diag_log format ["VCM_DOCTRINE_RECON: %1 detail=%2",_last,_group getVariable ["VCM_LastTaskDetail",[]]];
    [_last param [0,""] == "recon" && {_last param [1,""] == "completed"},"native entry teams reach and observe the assigned recon post"] call _assert;
    [_actors findIf {_x distance2D (_start select (_actors find _x)) > 5} >= 0,"recon task requires actual native travel"] call _assert;
    [_last param [3,-1] == 0,"recon observation never issues scripted suppression"] call _assert;
};
private _receiver = createGroup [west,true];
_receiver setVariable ["Vcm_Disable",false];
private _listener = _receiver createUnit ["B_Soldier_F",[5500,7000,0],[],0,"NONE"];
_listener disableAI "ALL"; _listener allowDamage false;
VCM_REPORTRANGE = 3000;
_group reveal [_enemy,4];
sleep 0.2;
private _reported = [7000,7170,0];
private _beforeKnowledge = 0;
private _afterKnowledge = 0;
private _sent = false;
isNil {
    _group setVariable ["VCM_ServerReconAfter",-1];
    _beforeKnowledge = _receiver knowsAbout _enemy;
    _sent = [_group,[[_enemy,_reported]],objNull] call VCM_fnc_ReconPublish;
    _afterKnowledge = _receiver knowsAbout _enemy;
};
[_sent && {(_receiver getVariable ["VCM_ScoutReports",[]]) findIf {_x select 1 isEqualTo _reported} >= 0},"radio report distributes the observed position to a friendly squad"] call _assert;
[_beforeKnowledge == _afterKnowledge,"radio reporting does not reveal a target's hidden native position"] call _assert;
[!([_group,[[_listener,_reported]],objNull] call VCM_fnc_ReconPublish),"recon report rejects a friendly target"] call _assert;
private _current = +(_group getVariable ["VCM_Objective",[]]);
if (_current isEqualTo []) exitWith {[false,"recon fixture requires a live assigned point before restart acceptance"] call _assert};
[["restartPoint","",_current select 2] call _order,"existing point can restart without being deleted"] call _assert;
[_group] call VCM_fnc_CommandTick;
[(_group getVariable ["VCM_Objective",[]]) select 5 > (_current select 5),"restart advances the point revision"] call _assert;
["point","defend",[6970,7000,0],10] call _order; [_group] call VCM_fnc_CommandTick;
_plan = [_group] call VCM_fnc_ObjectivePlan;
[_plan isNotEqualTo [],"defense-removal fixture has a physical plan"] call _assert;
if (_plan isNotEqualTo []) then {
    private _job = [_group,_plan] spawn VCM_fnc_ObjectiveTask;
    [{_group getVariable ["VCM_Task",[]] isNotEqualTo []},3] call _await;
    ["resetPoint","",[6970,7000,0]] call _order;
    [_group] call VCM_fnc_CommandTick;
    [{scriptDone _job},3] call _await;
    [scriptDone _job && {_group getVariable ["VCM_Objective",[]] isEqualTo []},"removing a point cancels its active native task"] call _assert;
    [_actors findIf {_x getVariable ["VCM_TaskKey",[]] isNotEqualTo [] || {!(_x checkAIFeature "PATH")} || {!(_x checkAIFeature "TARGET")}} < 0,
        "point removal clears reservations and restores owned native features"] call _assert;
};
["point","defend",[6970,7000,0],10] call _order; [_group] call VCM_fnc_CommandTick;
_plan = [_group] call VCM_fnc_ObjectivePlan;
[_plan isNotEqualTo [],"mission-cancellation fixture has a physical defense plan"] call _assert;
if (_plan isNotEqualTo []) then {
    private _job = [_group,_plan] spawn VCM_fnc_ObjectiveTask;
    sleep 0.3;
    private _waypoint = _group addWaypoint [[6800,7000,0],0]; _waypoint setWaypointName "DOCTRINE_MISSION_ORDER";
    [{scriptDone _job},3] call _await;
    [scriptDone _job && {(waypoints _group) findIf {waypointName _x == "DOCTRINE_MISSION_ORDER"} >= 0},
        "new mission orders cancel a defense task and survive cleanup"] call _assert;
    deleteWaypoint _waypoint;
    _group setBehaviour "COMBAT";
    {_x doFollow leader _group} forEach _actors;
    sleep 1;
};
["resetGroup"] call _order; [_group] call VCM_fnc_CommandTick;
_group setVariable ["VCM_ObjectiveAfter",-1];
_group reveal [_enemy,4]; _group reveal [_flanker,4];
sleep 0.3;
_group setVariable ["VCM_ThreatAxis",[0,time],true];
VCM_COUNTERFLANK = true;
private _flankPlan = [_group] call VCM_fnc_CounterFlankPlan;
[_flankPlan isNotEqualTo [] && {_flankPlan select 0 == _flanker},"counter-flank planner selects a known lateral contact"] call _assert;
if (_flankPlan isNotEqualTo []) then {
    private _before = (_flankPlan select 3) apply {getPosATL _x};
    _group setVariable ["VCM_NOAUTOTACTICS",false];
    [_group] call VCM_fnc_TacticalTick;
    _group setVariable ["VCM_NOAUTOTACTICS",true];
    [{(_group getVariable ["VCM_Task",[]]) param [1,""] == "counterflank"},3] call _await;
    private _jobKey = (_group getVariable ["VCM_Task",[]]) param [0,[]];
    [_jobKey isNotEqualTo [],"counter-flank task starts through the squad planner"] call _assert;
    [{_group getVariable ["VCM_Task",[]] isEqualTo []},65] call _await;
    [(_flankPlan select 3) findIf {_x distance2D (_before select ((_flankPlan select 3) find _x)) > 2} >= 0,
        "counter-flank response physically repositions its maneuver soldiers"] call _assert;
};
VCM_COUNTERFLANK = false;
// Use a fresh native group for withdrawal, isolating the prior authored-route cancellation fixture.
private _retiredGroup = _group;
private _retiredActors = +_actors;
["resetGroup"] call _order;
_retiredGroup setVariable ["Vcm_Disable",true];
sleep 0.5;
_group = createGroup [west,true];
_group setVariable ["VCM_NOAUTOTACTICS",true];
_group setVariable ["VCM_Skilldisable",true];
_actors = [];
for "_i" from 0 to 3 do {
    private _soldier = _group createUnit ["B_Soldier_F",[6970,6970 + 5 * _i,0],[],0,"NONE"];
    _soldier allowDamage false; _actors pushBack _soldier;
};
_unit = leader _group;
_group setCombatMode "GREEN"; _group setBehaviour "COMBAT";
_group reveal [_enemy,4]; _group call VCM_fnc_SquadExc;
sleep 1.5;
_group setVariable ["VCM_NextTactic",1e9];
["point","fallback",[6945,7000,0],10] call _order; [_group] call VCM_fnc_CommandTick;
_group setVariable ["VCM_ObjectiveAfter",-1];
private _fallback = [_group,"fallback"] call VCM_fnc_ObjectivePlan;
[_fallback isNotEqualTo [] && {_fallback select 0 select 1 == "fallback"},"fallback point provides covered withdrawal destinations"] call _assert;
if (_fallback isNotEqualTo []) then {
    private _job = [_group,[_enemy,[7000,7200,0],"casualties"]] spawn VCM_fnc_Retreat;
    [{scriptDone _job},110] call _await;
    diag_log format ["VCM_FALLBACK_RESULT: task=%1 detail=%2 context=%3 point=%4",
        _group getVariable ["VCM_LastTask",[]],_group getVariable ["VCM_LastTaskDetail",[]],
        _group getVariable ["VCM_ObjectiveContext",[]],_group getVariable ["VCM_FallbackPoint",[]]];
    [(_group getVariable ["VCM_LastTask",[]]) param [0,""] == "fallback" &&
        {(_group getVariable ["VCM_LastTask",[]]) param [1,""] == "completed"},"withdrawal executes the assigned fallback point using native travel"] call _assert;
    [_actors findIf {_x distance2D [6945,7000,0] > 10 + VCM_POINTARRIVAL} < 0,"both fallback teams physically arrive inside the assigned area and stopping tolerance"] call _assert;
};
["resetGroup"] call _order; [_group] call VCM_fnc_CommandTick;
private _date = date;
_group setCombatMode "YELLOW";
deleteVehicle _enemy;
_enemy = _enemyGroup createUnit ["O_Soldier_F",_unit getPos [80,0],[],0,"NONE"];
_enemy disableAI "ALL"; _enemy allowDamage false; _group reveal [_enemy,4];
[{private _known = [_unit,_enemy] call VCM_fnc_ContactPosition; _known isNotEqualTo [] && {_unit distance2D _known < 150}},5] call _await;
setDate [2035,6,24,0,0];
_unit addPrimaryWeaponItem "acc_flashlight";
_group enableGunLights "ForceOn";
sleep 1;
_group setVariable ["VCM_NightMode","blackout",true];
[_group] call VCM_fnc_NightTick;
sleep 0.3;
[!(_unit isFlashlightOn primaryWeapon _unit) && {_unit getVariable ["VCM_NightState",[]] isNotEqualTo []},
    "night blackout turns off an actual equipped flashlight"] call _assert;
private _laserUnit = _actors select 1;
_laserUnit addPrimaryWeaponItem "acc_pointer_IR";
_laserUnit linkItem "NVGoggles";
_group setVariable ["VCM_NightMode","auto",true];
_group reveal [_enemy,4];
sleep 0.3;
[_group] call VCM_fnc_NightTick;
sleep 0.3;
[_laserUnit isIRLaserOn primaryWeapon _laserUnit,"equipped NVG soldier uses an IR laser during night contact"] call _assert;
diag_log format ["VCM_NIGHT_LASER: active=%1 state=%2 feature=%3 items=%4 nvg=%5 contact=%6",
    _laserUnit isIRLaserOn primaryWeapon _laserUnit,_laserUnit getVariable ["VCM_NightState",[]],
    _laserUnit checkAIFeature "LIGHTS",assignedItems _laserUnit,hmd _laserUnit,
    [leader _group,_enemy] call VCM_fnc_ContactPosition];
{_x unlinkItem (hmd _x)} forEach _actors;
_unit addMagazine "ACE_HandFlare_White";
private _flareBefore = {(_x select 0) == "ACE_HandFlare_White"} count magazinesAmmoFull _unit;
_group setVariable ["VCM_NightMode","illuminate",true];
_group setVariable ["VCM_FlareAfter",-1];
[_group] call VCM_fnc_NightTick;
[{_unit getVariable ["VCM_LastFlare",[]] isNotEqualTo []},12] call _await;
private _flare = _unit getVariable ["VCM_LastFlare",[]];
diag_log format ["VCM_NIGHT_RESULT: flash=%1 laser=%2 flare=%3 throw=%4",_unit isFlashlightOn primaryWeapon _unit,
    _laserUnit isIRLaserOn primaryWeapon _laserUnit,_flare,VCM_ThrowInfo getOrDefault ["ACE_HandFlare_White",[]]];
[_flare isNotEqualTo [] && {!isNull (_flare select 1)},"illumination creates a real native carried hand-flare projectile"] call _assert;
[{(_x select 0) == "ACE_HandFlare_White"} count magazinesAmmoFull _unit < _flareBefore,"illumination consumes carried ammunition"] call _assert;
VCM_NIGHTDISCIPLINE = false;
[_group] call VCM_fnc_NightTick;
[_actors findIf {_x getVariable ["VCM_NightState",[]] isNotEqualTo [] || {!(_x checkAIFeature "LIGHTS")}} < 0,
    "disabling night discipline releases its attachment and native feature ownership"] call _assert;
setDate _date;
_enemy setPosATL [7000,7200,0];
[] call compile preprocessFileLineNumbers "autonomy.sqf";
if (isClass (configFile >> "CfgVehicles" >> "VCM_ModuleDoctrineDefend")) then {
    private _logicGroup = createGroup sideLogic;
    private _logic = _logicGroup createUnit ["VCM_ModuleDoctrineDefend",getPosATL _unit,[],0,"NONE"];
    [_logic,_actors,true] call VCM_fnc_ZeusModule;
    [{[_group] call VCM_fnc_Doctrine == "defend"},3] call _await;
    [[_group] call VCM_fnc_Doctrine == "defend","native module entry applies its synchronized-squad doctrine"] call _assert;
    deleteGroup _logicGroup;
};
["resetGroup"] call _order; [_group] call VCM_fnc_CommandTick;
_group setVariable ["Vcm_Disable",true]; _receiver setVariable ["Vcm_Disable",true];
sleep 0.5;
{deleteVehicle _x} forEach (_actors + _retiredActors + [_enemy,_flanker,_listener]);
deleteGroup _group; deleteGroup _retiredGroup; deleteGroup _enemyGroup; deleteGroup _receiver;
