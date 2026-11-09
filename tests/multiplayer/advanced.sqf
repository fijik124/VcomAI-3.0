/* Fixed owner-side jobs exercise coordination without transferring units to execute an order. */
VCM_MULTISQUAD = true;
VCM_CROSSOWNER_ESCORT = true;
VCM_COMBINEDARMS = true;
VCM_ACECASEVAC = true;
VCM_CoordTimes = createHashMap;
VCM_Debug = true;
sleep 2;
private _groups = [];
private _actors = [];
private _enemy = _opfor createUnit ["O_Soldier_F",[15300,15000,0],[],0,"NONE"];
_enemy disableAI "ALL";
_enemy allowDamage false;
for "_squad" from 0 to 2 do {
    private _squadGroup = createGroup [west,true];
    _squadGroup setVariable ["VCM_Skilldisable",true,true];
    _squadGroup setVariable ["VCM_NOAUTOTACTICS",true,true];
    for "_index" from 0 to 3 do {
        private _actor = _squadGroup createUnit ["B_Soldier_F",[15000 - 30 * _squad,15000 + 8 * _index,0],[],0,"NONE"];
        _actor allowDamage false;
        _actors pushBack _actor;
    };
    _squadGroup setCombatMode "GREEN";
    _squadGroup call VCM_fnc_SquadExc;
    _groups pushBack _squadGroup;
};
[_groups select 0,_first,"coordinated squad to HC1"] call _transfer;
[_groups select 1,_second,"coordinated squad to HC2"] call _transfer;
["requestCoord",_groups select 1,"forged-coord",[_enemy,[15300,15000,0],"squads",_groups select 0]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
sleep 0.75;
[_groups findIf {_x getVariable ["VCM_CoordMission",[]] isNotEqualTo []} < 0,"coordination rejects an HC claiming another owner's group"] call _assert;
["requestCoord",_groups select 1,"squad-coord",[_enemy,[15300,15000,0],"squads"]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
private _assigned = [{_groups findIf {_x getVariable ["VCM_LastSquadRole",[]] isEqualTo []} < 0},10] call _await;
[_assigned,"one HC request assigns squad roles across server and both HCs"] call _assert;
private _roles = _groups apply {(_x getVariable ["VCM_LastSquadRole",[]]) param [0,""]};
_roles sort true;
[_roles isEqualTo ["assault","flank","support"],"cross-owner squads receive distinct assault support and flank roles"] call _assert;
[_groups findIf {(_x getVariable ["VCM_LastSquadRole",[]]) param [2,-1] != groupOwner _x} < 0,"each squad assignment executes on its current owner"] call _assert;
private _telemetry = [{_groups findIf {
    private _info = _x getVariable ["VCM_DebugInfo",[]];
    _info param [0,-1] != groupOwner _x || {_info param [1,0] <= 0} || {count (_info param [7,[]]) > 5}
} < 0},5] call _await;
[_telemetry,"debugger receives correctly owned bounded telemetry from server and both HCs"] call _assert;
private _intent = [{_groups findIf {
    private _snapshot = _x getVariable ["VCM_DebugState",[]];
    count _snapshot != 6 || {count (_snapshot select 2) != 4} || {(_snapshot select 1) isEqualTo []}
} < 0},5] call _await;
[_intent,"debugger receives native command rows and recorded decision reasons from all three owners"] call _assert;
{private _order = _x addWaypoint [[14900,14900,0],0]; _order setWaypointName "MP_COORD_ABORT"} forEach _groups;
private _released = [{_groups findIf {_x getVariable ["VCM_CoordMission",[]] isNotEqualTo []} < 0},5] call _await;
[_released,"mission orders release coordination leases on all three owners"] call _assert;
{_x setVariable ["Vcm_Disable",true,true]} forEach _groups;
sleep 0.5;
{deleteVehicle _x} forEach _actors;
{deleteGroup _x} forEach _groups;
deleteVehicle _enemy;

private _infantry = createGroup [west,true];
_infantry setVariable ["VCM_Skilldisable",true,true];
_infantry setVariable ["VCM_NOAUTOTACTICS",true,true];
private _infantryUnits = [];
for "_i" from 0 to 2 do {
    private _actor = _infantry createUnit ["B_Soldier_F",[16000,16000 + 7 * _i,0],[],0,"NONE"];
    _actor allowDamage false;
    _infantryUnits pushBack _actor;
};
_infantry setCombatMode "GREEN";
_infantry call VCM_fnc_SquadExc;
private _crew = createGroup [west,true];
_crew setVariable ["Vcm_Disable",true,true];
_crew setVariable ["VCM_Skilldisable",true,true];
_crew setVariable ["VCM_NOAUTOTACTICS",true,true];
private _driver = _crew createUnit ["B_Soldier_F",[16015,16000,0],[],0,"NONE"];
_driver allowDamage false;
private _vehicle = createVehicle ["B_MRAP_01_F",[16015,16000,0],[],0,"CAN_COLLIDE"];
_vehicle setDir 90;
_vehicle allowDamage false;
_enemy = _opfor createUnit ["O_Soldier_F",[16300,16000,0],[],0,"NONE"];
_enemy allowDamage false;
_enemy disableAI "ALL";
[_infantry,_second,"escort infantry to HC2"] call _transfer;
[_crew,_first,"escort vehicle crew to HC1"] call _transfer;
["mountDriver",_crew,"mount-escort",[_vehicle]] remoteExecCall ["VCM_test_fnc_Scenario",_first];
private _mounted = [{owner _vehicle == _first && {driver _vehicle == _driver}},10] call _await;
[_mounted,"HC1 takes native driver and vehicle ownership before cooperation"] call _assert;
diag_log format ["VCM_ESCORT_BEFORE: infantryReady=%1 crewReady=%2 distance=%3 driver=%4 owner=%5 crewLease=%6 infantryLease=%7 crewWPs=%8",[_infantry] call VCM_fnc_CoordReady,[_crew] call VCM_fnc_CoordReady,leader _infantry distance2D _vehicle,driver _vehicle,owner _vehicle,_crew getVariable ["VCM_CoordMission",[]],_infantry getVariable ["VCM_CoordMission",[]],waypoints _crew];
["requestCoord",_infantry,"escort-coord",[_enemy,[16300,16000,0],"escort",_infantry,_vehicle]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
private _escorting = [{_infantry getVariable ["VCM_LastEscort",[]] isNotEqualTo [] && {_crew getVariable ["VCM_LastVehicleAssist",[]] isNotEqualTo []}},12] call _await;
[_escorting,"HC2 infantry and HC1 vehicle both execute a shared escort lease"] call _assert;
diag_log format ["VCM_ESCORT_AFTER: vehicle=%1 infantry=%2 vehicleJob=%3 infantryJob=%4",_vehicle getVariable ["VCM_InfantryPartner",[]],_infantry getVariable ["VCM_CoordMission",[]],_crew getVariable ["VCM_LastVehicleAssist",[]],_infantry getVariable ["VCM_LastEscort",[]]];
[groupOwner _infantry == _second && {groupOwner _crew == _first} && {owner _vehicle == _first},"cross-owner escort keeps both original owners"] call _assert;
sleep 1;
[_vehicle getVariable ["VCM_InfantryPartner",[]] isNotEqualTo [],"ordinary safety scans retain a valid remote infantry partner"] call _assert;
private _order = _crew addWaypoint [[16100,16100,0],0];
_order setWaypointName "MP_ESCORT_REPLACEMENT";
_released = [{_vehicle getVariable ["VCM_InfantryPartner",[]] isEqualTo [] && {_infantry getVariable ["VCM_CoordMission",[]] isEqualTo []}},6] call _await;
[_released,"new vehicle order cancels cross-owner escort and releases both leases"] call _assert;
[(waypoints _crew) findIf {waypointName _x == "MP_ESCORT_REPLACEMENT"} >= 0,"cross-owner escort cleanup preserves the replacement route"] call _assert;
// An interrupted attachment must be released by the next owner, including with ACE loaded.
["attachPatient",_infantry,"drag",[_infantryUnits select 1]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
private _attached = [{!isNull attachedTo (_infantryUnits select 1)},5] call _await;
[_attached,"AI casualty is physically attached on its current HC"] call _assert;
diag_log format ["VCM_EVAC_MP: record=%1 diag=%2",_infantry getVariable ["VCM_Evacuation",[]],_infantry getVariable ["VCM_TestEvacDiag",[]]];
[_infantry,2,"attached casualty to server"] call _transfer;
[isNull attachedTo (_infantryUnits select 1) && {(_infantryUnits select 1) getVariable ["VCM_EvacPatient",[]] isEqualTo []},"new owner detaches an interrupted casualty and clears owned records"] call _assert;
{_x setVariable ["Vcm_Disable",true,true]} forEach [_infantry,_crew];
sleep 0.5;
{deleteVehicle _x} forEach (_infantryUnits + [_driver,_vehicle,_enemy]);
deleteGroup _infantry;
deleteGroup _crew;
// Interrupt an actual full-room controller after exterior staging, then inspect its new owner.
VCM_BUILDINGCLEARING = true; VCM_FULLCLEAR = true; VCM_CQBSECTORS = true;
VCM_ADVANCEDMOVEMENT = false; VCM_FIREMOVEMENT = false; VCM_StealVeh = false;
private _clearGroup = createGroup [west,true];
_clearGroup setVariable ["VCM_Skilldisable",true,true];
_clearGroup setVariable ["VCM_NOAUTOTACTICS",true,true];
private _clearUnits = [];
for "_i" from 0 to 3 do {
    private _actor = _clearGroup createUnit ["B_Soldier_F",[8000,12000 + _i * 5,0],[],0,"NONE"];
    _actor allowDamage false; _clearUnits pushBack _actor;
};
private _clearHouse = createVehicle ["Land_i_House_Small_01_V1_F",[8025,12000,0],[],0,"CAN_COLLIDE"];
private _clearEnemy = _opfor createUnit ["O_Soldier_F",(_clearHouse buildingPos -1) select 0,[],0,"NONE"];
_clearEnemy disableAI "ALL"; _clearEnemy allowDamage false;
_clearGroup setCombatMode "GREEN"; _clearGroup setBehaviour "COMBAT";
_clearGroup reveal [_clearEnemy,4]; _clearGroup call VCM_fnc_SquadExc;
[_clearHouse] call VCM_fnc_CQBLayout;
private _ready = [{count ([_clearGroup] call VCM_fnc_TacticalUnits) >= 4 &&
    {([leader _clearGroup,_clearEnemy] call VCM_fnc_ContactPosition) isNotEqualTo []}},6] call _await;
diag_log format ["VCM_CQB_MP_READY: ready=%1 eligible=%2 plan=%3 flags=%4 units=%5",_ready,count ([_clearGroup] call VCM_fnc_TacticalUnits),
    ([_clearGroup,_clearEnemy] call VCM_fnc_ClearBuildingPlan) isNotEqualTo [],[VCM_BUILDINGCLEARING,VCM_FULLCLEAR,VCM_CQBSECTORS],
    _clearUnits apply {[currentCommand _x,_x getVariable ["VCM_MoveKey",[]],_x getVariable ["VCM_MBUSY",false]]}];
[_clearGroup,_clearEnemy] spawn VCM_fnc_ClearBuilding;
private _clearing = [{((_clearGroup getVariable ["VCM_CQBProgress",[]]) param [3,-1]) >= 0},40] call _await;
[_ready && {_clearing},"full room search is physically active before ownership transfer"] call _assert;
private _oldClearKey = (_clearGroup getVariable ["VCM_CQBSession",[]]) param [0,[]];
[_clearGroup,_first,"active room search to HC1"] call _transfer;
private _clearProbe = [_first,"room-handoff",[_clearGroup]] call _probe;
private _clearState = (_clearProbe param [3,[]]) param [0,[]];
[_clearGroup getVariable ["VCM_CQBSession",[]] isEqualTo [] &&
    {((_clearGroup getVariable ["VCM_CQBProgress",[]]) param [2,""]) == "owner-changed"},"new owner releases the room session and retains an interrupted search report"] call _assert;
[count _clearState > 0 && {_clearState select 2 == 1} &&
    {(_clearState select 5) findIf {(_x select 9) isEqualTo _oldClearKey || {!(_x select 10)} || {!(_x select 11)}} < 0},
    "room-search handoff restores native behavior and leaves exactly one controller"] call _assert;
_clearGroup setVariable ["Vcm_Disable",true,true]; sleep 0.5;
{deleteVehicle _x} forEach (_clearUnits + [_clearHouse,_clearEnemy]);
deleteGroup _clearGroup;
VCM_Debug = false;
