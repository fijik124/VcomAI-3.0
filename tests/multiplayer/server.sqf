if (!isServer) exitWith {};
waitUntil {sleep 0.1; missionNamespace getVariable ["VCM_ServerReady", false]};
VCM_MP_Reports = createHashMap;
VCM_MP_Count = 0;
VCM_MP_Failures = 0;
private _assert = {
    params ["_condition", "_name"];
    VCM_MP_Count = VCM_MP_Count + 1;
    if (!_condition) then {VCM_MP_Failures = VCM_MP_Failures + 1};
    diag_log format ["VCM_MP_%1: %2", ["FAIL", "PASS"] select _condition, _name];
};
private _finish = {diag_log format ["VCM_MP_DONE: %1 checks, %2 failures", VCM_MP_Count, VCM_MP_Failures]};
[] call compile preprocessFileLineNumbers "mp\addon-layout.sqf";
private _await = {
    params ["_condition", ["_seconds", 15]];
    private _deadline = diag_tickTime + _seconds;
    waitUntil {sleep 0.1; call _condition || {diag_tickTime > _deadline}};
    call _condition
};
private _owners = {
    private _result = [];
    {if ((_x find ":joined") >= 0) then {_result pushBack parseNumber ((_x splitString ":") select 0)}} forEach keys VCM_MP_Reports;
    _result sort true;
    _result
};
private _probe = {
    params ["_owner", "_label", ["_groups", []]];
    private _key = format ["%1:%2", _owner, _label];
    if (_owner == 2) then {[_label, _groups] call VCM_test_fnc_Probe} else {
        [_label, _groups] remoteExecCall ["VCM_test_fnc_Probe", _owner];
    };
    [{!isNil {VCM_MP_Reports get _key}}, 15] call _await;
    VCM_MP_Reports getOrDefault [_key, []]
};
private _transfer = {
    params ["_group", "_owner", "_label"];
    private _accepted = _group setGroupOwner _owner;
    [_accepted, _label + ": engine accepts transfer"] call _assert;
    private _arrived = [{groupOwner _group == _owner}, 15] call _await;
    [_arrived, _label + ": group reaches requested owner"] call _assert;
    sleep 3;
};
VCM_WARNDIST = 731;
VCM_COVERSEARCH = false;
VCM_SIDEENABLED = [west, east];
(VCM_AIDIFA select 0) set [1, 0.19];
VCM_FIREMOVEMENT = false;
VCM_ADVANCEDMOVEMENT = false;
VCM_StealVeh = false;
VCM_FRMCHANGE = false;
VCM_ARTYENABLE = false;
sleep 2;
private _initialSettings = call VCM_fnc_SettingsSnapshot;
diag_log "VCM_MP_SERVER_READY";
private _nextStatus = diag_tickTime;
private _connected = [{
    if (diag_tickTime >= _nextStatus) then {
        diag_log format ["VCM_MP_CONNECTION: users=%1 slots=%2", allUsers, (entities "HeadlessClient_F") apply {[owner _x, isPlayer _x]}];
        _nextStatus = diag_tickTime + 10;
    };
    count (call _owners) >= 1
}, 75] call _await;
[_connected, "first headless client joins the running mission"] call _assert;
if (!_connected) exitWith {call _finish};
private _first = (call _owners) select 0;
private _joined = VCM_MP_Reports get format ["%1:joined", _first];
[_joined select 0, "first headless client reports didJIP"] call _assert;
[_joined select 1, "first headless client initializes VCOM settings"] call _assert;
if (VCM_TestAddonChecks isNotEqualTo []) then {
    [count (_joined param [4,[]]) == count VCM_TestAddonChecks && {(_joined select 4) findIf {!_x} < 0},
        "first HC loads every addon module and its functions"] call _assert;
};
[(_joined select 2) isEqualTo _initialSettings, "JIP receives server side and skill arrays"] call _assert;
private _forgedKey = format ["%1:forged", _first];
[{!isNil {VCM_MP_Reports get _forgedKey}}, 10] call _await;
[VCM_MP_Reports getOrDefault [_forgedKey, false], "client-originated settings RPC is rejected"] call _assert;
private _requestKey = format ["%1:requested", _first];
[{!isNil {VCM_MP_Reports get _requestKey}}, 10] call _await;
[VCM_MP_Reports getOrDefault [_requestKey, false], "headless client receives an explicitly requested settings reply"] call _assert;

VCM_WARNDIST = 946;
VCM_COVERSEARCH = true;
(VCM_AIDIFA select 0) set [1, 0.27];
sleep 2;
private _updatedSettings = call VCM_fnc_SettingsSnapshot;
private _updated = [_first, "updated"] call _probe;
[count _updated > 0 && {(_updated select 2) isEqualTo _updatedSettings}, "live settings changes reach existing headless client"] call _assert;
diag_log "VCM_MP_SECOND_READY";
_connected = [{count (call _owners) >= 2}, 75] call _await;
[_connected, "second headless client joins later"] call _assert;
if (!_connected) exitWith {call _finish};
private _second = (call _owners) select 1;
_joined = VCM_MP_Reports get format ["%1:joined", _second];
[_joined select 0, "second headless client reports didJIP"] call _assert;
if (VCM_TestAddonChecks isNotEqualTo []) then {
    [count (_joined param [4,[]]) == count VCM_TestAddonChecks && {(_joined select 4) findIf {!_x} < 0},
        "second HC loads every addon module and its functions"] call _assert;
};
[(_joined select 2) isEqualTo _updatedSettings, "later join receives current settings rather than defaults"] call _assert;

if (missionNamespace getVariable ["VCM_MP_AdvancedOnly",false]) exitWith {
    private _opfor = createGroup [east,true];
    _opfor setVariable ["Vcm_Disable",true,true];
    [] call compile preprocessFileLineNumbers "mp\advanced.sqf";
    deleteGroup _opfor;
    call _finish;
};
private _group = createGroup [west, true];
_group setVariable ["VCM_Skilldisable", true, true];
private _unit = _group createUnit ["B_Soldier_F", [1000,1000,0], [], 0, "NONE"];
_unit allowDamage false;
private _building = createVehicle ["Land_i_House_Big_01_V1_F", [1010,1010,0], [], 0, "NONE"];
private _hold = _group addWaypoint [[1010,1010,0], 0];
_hold setWaypointName "MP_AUTHORED_HOLD";
_hold setWaypointType "HOLD";
_group setCurrentWaypoint _hold;
_group call VCM_fnc_SquadExc;
sleep 1;
["garrison", _group, "garrison"] call VCM_test_fnc_Scenario;
sleep 0.5;
[_group getVariable ["VCM_GarrisonBusy", false], "garrison is active before ownership transfer"] call _assert;
private _serverRun = _group getVariable ["VCM_RunId", []];
[_group, _first, "server to HC during garrison"] call _transfer;
private _serverState = [2, "garrison-old", [_group]] call _probe;
private _clientState = [_first, "garrison-new", [_group]] call _probe;
private _old = (_serverState param [3, []]) param [0, []];
private _new = (_clientState param [3, []]) param [0, []];
[count _old > 0 && {_old select 2 == 0}, "old owner removes its controller"] call _assert;
[count _new > 0 && {_new select 0} && {_new select 2 == 1}, "new owner runs exactly one controller"] call _assert;
[count _new > 0 && {(_new select 3) isNotEqualTo _serverRun}, "new owner uses a fresh run token"] call _assert;
[(waypoints _group) findIf {waypointName _x == "MP_AUTHORED_HOLD"} >= 0, "authored HOLD survives transfer"] call _assert;
[count _new > 0 && {(_new select 5 select 0 select 4)}, "pathfinding remains enabled on the new owner"] call _assert;

["releaseHold", _group, "release"] remoteExec ["VCM_test_fnc_Scenario", _first];
sleep 0.75;
["move", _group, "move-cancelled", [1500,1500,0]] remoteExec ["VCM_test_fnc_Scenario", _first];
sleep 1;
private _moving = [_first, "move-started", [_group]] call _probe;
private _movingState = (_moving param [3, []]) param [0, []];
[count _movingState > 0 && {(_movingState select 5 select 0 select 3) isNotEqualTo []}, "movement is active on HC before transfer"] call _assert;
[_group, 2, "HC to server during movement"] call _transfer;
private _moveKey = format ["%1:move-cancelled", _first];
[{!isNil {VCM_MP_Reports get _moveKey}}, 10] call _await;
private _moveResult = VCM_MP_Reports getOrDefault [_moveKey, [true]];
[!(_moveResult select 0) && {!(_moveResult param [2, true])}, "old owner's movement script cancels after losing locality"] call _assert;
_serverState = [2, "return-new", [_group]] call _probe;
_clientState = [_first, "return-old", [_group]] call _probe;
_new = (_serverState param [3, []]) param [0, []];
_old = (_clientState param [3, []]) param [0, []];
[count _new > 0 && {_new select 2 == 1}, "server restarts a controller when ownership returns"] call _assert;
[count _old > 0 && {_old select 2 == 0}, "headless client removes its previous controller"] call _assert;

// Removing the HOLD lets the new owner clear inherited garrison state.
_hold setWaypointType "MOVE";
sleep 1;
[!(_group getVariable ["VCM_GarrisonBusy", false]), "garrison state releases after its order changes"] call _assert;
_unit addBackpack "B_HMG_01_weapon_F";
private _opfor = createGroup [east, true];
_opfor setVariable ["Vcm_Disable", true, true];
private _target = _opfor createUnit ["O_Soldier_F", [1200,1000,0], [], 0, "NONE"];
_target disableAI "ALL";
_target allowDamage false;
_group reveal [_target, 4];
["deploy", _group, "deploy"] call VCM_test_fnc_Scenario;
sleep 0.25;
[_unit getVariable ["VCM_DeployBusy", false], "static deployment starts before transfer"] call _assert;
[_group, _first, "server to HC during static deployment"] call _transfer;
sleep 1;
[backpack _unit == "B_HMG_01_weapon_F", "cancelled deployment keeps the carried weapon"] call _assert;
[count (nearestObjects [_unit, ["StaticWeapon"], 20]) == 0, "cancelled deployment removes its temporary empty static"] call _assert;

VCM_FIREMOVEMENT = true;
VCM_ADVANCEDMOVEMENT = true;
sleep 2;
private _boundGroup = createGroup [west, true];
_boundGroup setVariable ["VCM_Skilldisable", true, true];
private _boundSoldiers = [];
private _positions = [[6000,5985,0], [6000,6015,0], [5995,5980,0], [5995,6020,0]];
{
    private _soldier = _boundGroup createUnit [_x, _positions select _forEachIndex, [], 0, "NONE"];
    _soldier setPosATL (_positions select _forEachIndex);
    _soldier setDir 90;
    _soldier allowDamage false;
    _boundSoldiers pushBack _soldier;
} forEach ["B_Soldier_F", "B_Soldier_F", "B_Soldier_F", "B_Soldier_AR_F"];
private _boundTarget = _opfor createUnit ["O_Soldier_F", [6200,6000,0], [], 0, "NONE"];
_boundTarget disableAI "ALL";
_boundTarget allowDamage false;
_boundGroup setCombatMode "YELLOW";
_boundGroup setBehaviour "COMBAT";
_boundGroup call VCM_fnc_SquadExc;
sleep 0.5;
_boundGroup reveal [_boundTarget, 4];
["bound", _boundGroup, "bound"] call VCM_test_fnc_Scenario;
sleep 0.25;
private _boundState = _boundGroup getVariable ["VCM_BoundState", []];
[_boundState isNotEqualTo [], "coordinated movement is active before transfer"] call _assert;
private _oldBoundKey = _boundState param [0, []];
[_boundGroup, _first, "server to HC during coordinated movement"] call _transfer;
_serverState = [2, "bound-old", [_boundGroup]] call _probe;
_clientState = [_first, "bound-new", [_boundGroup]] call _probe;
_old = (_serverState param [3, []]) param [0, []];
_new = (_clientState param [3, []]) param [0, []];
[count _old > 0 && {_old select 2 == 0}, "coordinated squad releases the old controller"] call _assert;
[count _new > 0 && {_new select 2 == 1}, "coordinated squad acquires one HC controller"] call _assert;
private _oldKeysGone = count _new > 0 && {(_new select 5) findIf {(_x select 2) isEqualTo _oldBoundKey} < 0};
[_oldKeysGone, "new owner releases inherited maneuver reservations"] call _assert;

// A request from HC2 must be able to reach infantry and artillery owned by HC1.
VCM_CROSSOWNER_SUPPORT = true;
VCM_ARTYENABLE = true;
VCM_ARTYDELAY = 10;
VCM_WARNDIST = 400;
VCM_REACTIVESUPPRESSION = false;
VCM_COMBINEDARMS = false;
VCM_BUILDINGCLEARING = false;
VCM_FIREMOVEMENT = false;
sleep 2;
private _caller = createGroup [west,true];
_caller setVariable ["VCM_Skilldisable",true,true];
_caller setVariable ["VCM_NOAUTOTACTICS",true,true];
private _callerUnit = _caller createUnit ["B_Soldier_F",[11000,11000,0],[],0,"NONE"];
_callerUnit allowDamage false;
private _responder = createGroup [west,true];
_responder setVariable ["VCM_Skilldisable",true,true];
_responder setVariable ["VCM_NOAUTOTACTICS",true,true];
private _responderUnit = _responder createUnit ["B_Soldier_F",[11050,11000,0],[],0,"NONE"];
_responderUnit allowDamage false;
private _supportTarget = _opfor createUnit ["O_Soldier_F",[11400,11000,0],[],0,"NONE"];
_supportTarget disableAI "ALL";
_supportTarget allowDamage false;
_caller call VCM_fnc_SquadExc;
_responder call VCM_fnc_SquadExc;
[_caller,_second,"support caller to HC2"] call _transfer;
[_responder,_first,"support responder to HC1"] call _transfer;
["requestSupport",_caller,"forged-support",[_supportTarget,[11400,11000,0],"reinforcement",_responder]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
sleep 1;
[_responder getVariable ["VCM_LastSupport",[]] isEqualTo [], "support relay rejects an HC claiming another owner's group"] call _assert;
["requestSupport",_caller,"support",[_supportTarget,[11400,11000,0],"reinforcement"]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
private _received = [{_responder getVariable ["VCM_LastSupport",[]] isNotEqualTo []},10] call _await;
[_received, "HC2 reinforcement request reaches an HC1 responder"] call _assert;
[_received && {(_responder getVariable ["VCM_LastSupport",[]]) select 2 == _first}, "reinforcement order executes on the responder's owner"] call _assert;
// No fire mission may start while the fixture's vehicle is still changing owner.
VCM_ARTYENABLE = false;
sleep 2;
private _mortar = createVehicle ["B_Mortar_01_F",[10600,11000,0],[],0,"CAN_COLLIDE"];
// Transfer a registered foot crew before seating it; native setGroupOwner can eject seated leaders.
private _mortarGroup = createGroup [west,true];
_mortarGroup setVariable ["Vcm_Disable",true,true];
private _mortarGunner = _mortarGroup createUnit ["B_Soldier_F",[10600,11000,0],[],0,"NONE"];
_mortarGunner allowDamage false;
_mortar allowDamage false;
_mortarGroup setVariable ["VCM_Skilldisable",true,true];
_mortarGroup setVariable ["VCM_NOAUTOTACTICS",true,true];
sleep 0.5;
[_mortarGroup,_first,"artillery crew to HC1"] call _transfer;
["mountArtillery",_mortarGroup,"mount",[_mortar]] remoteExecCall ["VCM_test_fnc_Scenario",_first];
private _gunOwned = [{owner _mortar == _first && {gunner _mortar == _mortarGunner}},10] call _await;
[_gunOwned,"HC-owned artillery crew takes native control of its mortar"] call _assert;
["artilleryCounter",_mortarGroup,"counter"] remoteExecCall ["VCM_test_fnc_Scenario",_first];
sleep 0.5;
diag_log format ["VCM_MP_ARTY_READY: owner=%1 crewOwner=%2 mission=%3",owner _mortar,groupOwner _mortarGroup,_mortar getVariable ["VCM_LastFireMission",[]]];
VCM_ARTYENABLE = true;
sleep 2;
["requestSupport",_caller,"artillery",[_supportTarget,[11400,11000,0],"artillery"]] remoteExecCall ["VCM_test_fnc_Scenario",_second];
private _fireMission = [{_mortar getVariable ["VCM_LastFireMission",[]] isNotEqualTo []},10] call _await;
[_fireMission, "HC2 artillery request reaches an HC1-owned mortar"] call _assert;
diag_log format ["VCM_MP_ARTY_RESULT: owner=%1 crewOwner=%2 mission=%3",owner _mortar,groupOwner _mortarGroup,_mortar getVariable ["VCM_LastFireMission",[]]];
[_fireMission && {(_mortar getVariable ["VCM_LastFireMission",[]]) select 3 == _first}, "HE fire mission executes on the gun's current owner"] call _assert;
private _fired = [{_mortar getVariable ["VCM_TestArtyShots",0] > 0},25] call _await;
[_fired, "remote mortar fires a real native artillery projectile"] call _assert;

// Stored grenades remain conserved when a real indoor unit changes owner.
private _inventoryGroup = createGroup [west,true];
_inventoryGroup setVariable ["VCM_Skilldisable",true,true];
_inventoryGroup setVariable ["VCM_NOAUTOTACTICS",true,true];
private _inventoryUnit = _inventoryGroup createUnit ["B_Soldier_F",[12000,12000,0],[],0,"NONE"];
_inventoryUnit allowDamage false;
private _barracks = createVehicle ["Land_i_Barracks_V1_F",[12000,12000,0],[],0,"CAN_COLLIDE"];
sleep 0.2;
private _inside = [];
{_inventoryUnit setPosATL _x; if ([_inventoryUnit] call VCM_fnc_InsideBarracks) exitWith {_inside = _x}} forEach (_barracks buildingPos -1);
[_inside isNotEqualTo [], "multiplayer barracks has a confirmed indoor position"] call _assert;
{_inventoryUnit removeMagazines _x} forEach compatibleMagazines "Throw";
_inventoryUnit addMagazine "HandGrenade";
_inventoryUnit addMagazine "HandGrenade";
_inventoryGroup call VCM_fnc_SquadExc;
private _stored = [{count (_inventoryUnit getVariable ["VCM_StoredGrenades",[]]) == 2},5] call _await;
[_stored, "server stores the indoor unit's two grenades"] call _assert;
[_inventoryGroup,_first,"indoor inventory to HC1"] call _transfer;
private _inventoryProbe = [_first,"inventory-indoor",[_inventoryGroup]] call _probe;
private _inventoryState = (_inventoryProbe param [3,[]]) param [0,[]];
private _unitState = (_inventoryState param [5,[]]) param [0,[]];
[count _unitState > 0 && {count (_unitState select 6) == 2} && {!("HandGrenade" in (_unitState select 7))},
    "HC handoff conserves stored grenades and keeps them unavailable indoors"] call _assert;
["leaveBarracks",_inventoryGroup,"outside",[12100,12000,0]] remoteExecCall ["VCM_test_fnc_Scenario",_first];
sleep 1;
_inventoryProbe = [_first,"inventory-outdoor",[_inventoryGroup]] call _probe;
_inventoryState = (_inventoryProbe param [3,[]]) param [0,[]];
_unitState = (_inventoryState param [5,[]]) param [0,[]];
[count _unitState > 0 && {(_unitState select 6) isEqualTo []} && {{_x == "HandGrenade"} count (_unitState select 7) == 2},
    "HC restores exactly two grenades after the unit leaves the barracks"] call _assert;

private _retreatGroup = createGroup [west,true];
_retreatGroup setVariable ["VCM_Skilldisable",true,true];
_retreatGroup setVariable ["VCM_NOAUTOTACTICS",true,true];
private _retreatUnits = [];
for "_i" from 0 to 3 do {
    private _soldier = _retreatGroup createUnit ["B_Soldier_F",[13000,13000 + _i * 6,0],[],0,"NONE"];
    _soldier allowDamage false;
    _retreatUnits pushBack _soldier;
};
private _retreatTarget = _opfor createUnit ["O_Soldier_F",[13200,13000,0],[],0,"NONE"];
_retreatTarget disableAI "ALL";
_retreatTarget allowDamage false;
_retreatGroup call VCM_fnc_SquadExc;
sleep 0.5;
_retreatGroup reveal [_retreatTarget,4];
[_retreatGroup,[_retreatTarget,[13200,13000,0],"handoff"]] spawn VCM_fnc_Retreat;
sleep 0.5;
private _retreatState = _retreatGroup getVariable ["VCM_Task",[]];
[_retreatState isNotEqualTo [], "withdrawal is active before locality transfer"] call _assert;
private _oldTaskKey = _retreatState param [0,[]];
[_retreatGroup,_first,"active withdrawal to HC1"] call _transfer;
private _retreatProbe = [_first,"retreat-handoff",[_retreatGroup]] call _probe;
private _newRetreat = (_retreatProbe param [3,[]]) param [0,[]];
[count _newRetreat > 0 && {_newRetreat select 2 == 1}, "transferred withdrawal receives exactly one HC controller"] call _assert;
[count _newRetreat > 0 && {(_newRetreat select 5) findIf {(_x select 9) isEqualTo _oldTaskKey} < 0},
    "new owner releases inherited withdrawal reservations"] call _assert;

[] call compile preprocessFileLineNumbers "mp\advanced.sqf";
diag_log "VCM_MP_DISCONNECT_READY";
private _recovered = [{groupOwner _group == 2}, 35] call _await;
[_recovered, "disconnect returns group ownership to server"] call _assert;
sleep 3;
_serverState = [2, "disconnect-recovery", [_group]] call _probe;
_new = (_serverState param [3, []]) param [0, []];
[count _new > 0 && {_new select 2 == 1}, "server controller recovers after HC disconnect"] call _assert;
_serverState = [2, "bound-recovery", [_boundGroup]] call _probe;
_new = (_serverState param [3, []]) param [0, []];
[groupOwner _boundGroup == 2 && {count _new > 0} && {_new select 2 == 1}, "coordinated squad also recovers after disconnect"] call _assert;
[(waypoints _group) findIf {waypointName _x == "MP_AUTHORED_HOLD"} >= 0, "authored route survives disconnect recovery"] call _assert;
_serverState = [2,"retreat-recovery",[_retreatGroup]] call _probe;
_newRetreat = (_serverState param [3,[]]) param [0,[]];
[groupOwner _retreatGroup == 2 && {count _newRetreat > 0} && {_newRetreat select 2 == 1}, "withdrawal squad controller recovers after HC disconnect"] call _assert;
{_x setVariable ["Vcm_Disable",true,true]} forEach [_caller,_responder,_mortarGroup,_inventoryGroup,_retreatGroup];
_group setVariable ["Vcm_Disable", true, true];
_boundGroup setVariable ["Vcm_Disable", true, true];
sleep 0.5;
deleteVehicle _unit;
deleteVehicle _target;
deleteVehicle _building;
{deleteVehicle _x} forEach _boundSoldiers;
deleteVehicle _boundTarget;
{deleteVehicle _x} forEach ([_callerUnit,_responderUnit,_supportTarget,_inventoryUnit,_barracks,_retreatTarget] + _retreatUnits + crew _mortar + [_mortar]);
{deleteGroup _x} forEach [_caller,_responder,_mortarGroup,_inventoryGroup,_retreatGroup];
deleteGroup _boundGroup;
deleteGroup _group;
deleteGroup _opfor;
call _finish;
