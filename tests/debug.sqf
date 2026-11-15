/* Real graphical client: camera-relative labels and control lifetime in gameplay and Zeus. */
disableSerialization;
private _count = 0;
private _failures = 0;
private _assert = {
    params ["_condition","_name"];
    _count = _count + 1;
    if (!_condition) then {_failures = _failures + 1};
    diag_log format ["VCM_DEBUG_TEST_%1: %2",["FAIL","PASS"] select _condition,_name];
};
private _await = {
    params ["_condition",["_seconds",10]];
    private _deadline = diag_tickTime + _seconds;
    waitUntil {sleep 0.1; call _condition || {diag_tickTime > _deadline}};
    call _condition
};
private _ready = [{hasInterface && {!isNull player} && {!isNull findDisplay 46} &&
    {missionNamespace getVariable ["VCM_ServerReady",false]}},30] call _await;
[_ready,"test runs with an actual player display and VCOM startup"] call _assert;
if (!_ready) exitWith {diag_log format ["VCM_DEBUG_TEST_DONE: %1 checks, %2 failures",_count,_failures]; endMission "LOSER"};
VCM_Debug = false;
VCM_DEBUGOVERLAY = true;
VCM_DebugStatusUntil = -1;
[] call VCM_fnc_DebugUI;
[isNull (uiNamespace getVariable ["VCM_DebugPanel",controlNull]) &&
    {missionNamespace getVariable ["VCM_DebugDrawID",-1] < 0},"default local preference draws nothing while server debugging is off"] call _assert;
VCM_Debug = true;
VCM_DEBUGINTERVAL = 0.5;
VCM_DEBUGDISTANCE = 100;
private _group = createGroup [west,true];
_group setVariable ["VCM_NOAUTOTACTICS",true];
_group setVariable ["VCM_Skilldisable",true];
for "_i" from 0 to 3 do {
    private _unit = _group createUnit ["B_Soldier_F",[2200,2000 + _i * 4,0],[],0,"NONE"];
    _unit allowDamage false;
};
_group call VCM_fnc_SquadExc;
private _camera = "camera" camCreate [2180,1980,8];
_camera cameraEffect ["internal","back"];
cameraEffectEnableHUD true;
_camera camSetTarget leader _group; _camera camCommit 0;
private _shown = [{
    private _panel = uiNamespace getVariable ["VCM_DebugPanel",controlNull];
    !isNull _panel && {ctrlShown _panel} && {ctrlParent _panel == findDisplay 46} &&
    {count (missionNamespace getVariable ["VCM_DebugVisible",[]]) == 4}
},10] call _await;
[_shown,"main debugger enables the gameplay panel and four real unit labels"] call _assert;
[(missionNamespace getVariable ["VCM_DebugCameraPosition",[0,0,0]]) distance2D player > 1000 &&
    {missionNamespace getVariable ["VCM_DebugSelectedGroup",grpNull] == _group},
    "debugger finds the squad near a scripted camera far from the player's body"] call _assert;
private _panel = uiNamespace getVariable ["VCM_DebugPanel",controlNull];
[!isNull _panel && {(ctrlPosition _panel select 2) > 0} && {(ctrlPosition _panel select 3) > 0} &&
    {ctrlText _panel find "VCOM Edited by Fijik" >= 0},"gameplay panel contains readable debugger content at a nonzero size"] call _assert;
private _draw = missionNamespace getVariable ["VCM_DebugDrawID",-1];
for "_i" from 0 to 3 do {[] call VCM_fnc_DebugUI};
[_draw >= 0 && {_draw == (missionNamespace getVariable ["VCM_DebugDrawID",-1])},"repeated updates retain one Draw3D handler"] call _assert;
VCM_SettingsReady = false;
[] call VCM_fnc_DebugUI;
[ctrlText (uiNamespace getVariable ["VCM_DebugPanel",controlNull]) find "Waiting for server settings" >= 0,
    "waiting clients see a server-settings status panel"] call _assert;
VCM_SettingsReady = true;
VCM_DebugNextUI = -1;
_camera setPos [4000,4000,8]; sleep 0.3;
[] call VCM_fnc_DebugUI;
[VCM_DebugVisible isEqualTo [] && {ctrlText (uiNamespace getVariable ["VCM_DebugPanel",controlNull]) find "Waiting for fresh AI telemetry" >= 0},
    "an empty camera area explains missing data instead of showing a blank debugger"] call _assert;
VCM_DEBUGOVERLAY = false;
[] call VCM_fnc_DebugUI;
[isNull (uiNamespace getVariable ["VCM_DebugPanel",controlNull]) && {VCM_DebugDrawID < 0} &&
    {VCM_DebugVisible isEqualTo []},"local opt-out removes the panel, labels and drawing handler"] call _assert;
_camera cameraEffect ["terminate","back"]; camDestroy _camera;
private _logicGroup = createGroup sideLogic;
private _curator = _logicGroup createUnit ["ModuleCurator_F",[0,0,0],[],0,"NONE"];
player assignCurator _curator;
_curator addCuratorEditableObjects [units _group,true];
[{!isNull getAssignedCuratorLogic player},10] call _await;
openCuratorInterface;
private _zeus = [{!isNull findDisplay 312 && {!isNull curatorCamera}},10] call _await;
[_zeus,"native Zeus interface opens on the test client"] call _assert;
if (_zeus) then {
    curatorCamera setPos [2180,1980,15];
    curatorCamera setVectorDirAndUp [[1,1,-0.6],[0,0,1]];
    VCM_DEBUGOVERLAY = true; VCM_DebugNextUI = -1;
    private _zeusPanel = [{
        private _panel = uiNamespace getVariable ["VCM_DebugPanel",controlNull];
        !isNull _panel && {ctrlShown _panel} && {ctrlParent _panel == findDisplay 312} &&
        {count (missionNamespace getVariable ["VCM_DebugVisible",[]]) == 4}
    },10] call _await;
    [_zeusPanel,"Zeus owns a visible debugger panel and camera-local unit labels"] call _assert;
    [(VCM_DebugCameraPosition distance2D player) > 1000 && {VCM_DebugSelectedGroup == _group},
        "Zeus telemetry follows curator camera rather than the player's distant body"] call _assert;
    findDisplay 312 closeDisplay 2;
    [{isNull findDisplay 312},5] call _await;
    private _returned = [{
        private _panel = uiNamespace getVariable ["VCM_DebugPanel",controlNull];
        !isNull _panel && {ctrlParent _panel == findDisplay 46}
    },5] call _await;
    [_returned,"closing Zeus recreates the panel on the gameplay display"] call _assert;
};
VCM_Debug = false; VCM_DebugStatusUntil = -1;
[] call VCM_fnc_DebugUI;
[isNull (uiNamespace getVariable ["VCM_DebugPanel",controlNull]) && {VCM_DebugDrawID < 0},
    "disabling the main debugger cleans up the panel and Draw3D handler"] call _assert;
_group setVariable ["Vcm_Disable",true];
{deleteVehicle _x} forEach units _group;
deleteGroup _group;
unassignCurator _curator; deleteVehicle _curator; deleteGroup _logicGroup;
diag_log format ["VCM_DEBUG_TEST_DONE: %1 checks, %2 failures",_count,_failures];
endMission (["END1","LOSER"] select (_failures > 0));
