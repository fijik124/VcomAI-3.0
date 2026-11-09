/* Physical two-floor traversal, including rooms without a distinct native buildingPos goal. */
VCM_ADVANCEDMOVEMENT = false; VCM_FIREMOVEMENT = false; VCM_StealVeh = false;
VCM_MULTISQUAD = false; VCM_ARTYENABLE = false; VCM_Debug = true;
private _houses = (nearestTerrainObjects [[worldSize / 2,worldSize / 2,0],["HOUSE"],worldSize,false,true]) select {typeOf _x == "Land_i_House_Big_01_V1_F"};
[_houses isNotEqualTo [],"Altis contains a native two-floor test building"] call _assert;
if (_houses isEqualTo []) exitWith {};
private _isolated = _houses select {count (nearestTerrainObjects [getPosATL _x,["HOUSE"],25,false,true]) == 1};
private _building = (_isolated + _houses) select 0;
private _entrance = _building buildingExit 0;
private _approach = _building getPos [22,_building getDir _entrance];
diag_log format ["VCM_CQB_TERRAIN: position=%1 exits=%2",getPosATL _building,_entrance];
// Establish native reachability before testing the controller against this terrain fixture.
private _probeGroup = createGroup [west,true]; _probeGroup setVariable ["Vcm_Disable",true];
private _probe = _probeGroup createUnit ["B_Soldier_F",_approach,[],0,"NONE"];
_probe allowDamage false; _probeGroup setBehaviour "AWARE"; _probeGroup setSpeedMode "FULL";
private _upper = (_building buildingPos -1) select 3;
_probe doMove _upper;
private _probeUntil = diag_tickTime + 50;
waitUntil {sleep 0.5; abs ((getPosASL _probe select 2) - (ATLToASL _upper select 2)) < 0.8 && {_probe distance2D _upper < 4} || {diag_tickTime > _probeUntil}};
private _nativeReachable = _probe distance2D _upper < 4 && {abs ((getPosASL _probe select 2) - (ATLToASL _upper select 2)) < 0.8};
diag_log format ["VCM_CQB_NATIVE_BASELINE: position=%1 target=%2 command=%3 reachable=%4",getPosATL _probe,_upper,currentCommand _probe,_nativeReachable];
[_nativeReachable,"native AI can reach this fixture's upper floor before VCOM control"] call _assert;
deleteVehicle _probe; deleteGroup _probeGroup;
{[_building,_x select 0,0] call BIS_fnc_Door} forEach ([_building] call VCM_fnc_CQBDoors);
if (!_nativeReachable) exitWith {};
private _group = createGroup [west,true];
_group setVariable ["VCM_Skilldisable",true]; _group setVariable ["VCM_NOAUTOTACTICS",true];
private _actors = [];
for "_i" from 0 to 3 do {
    private _position = (_approach getPos [5 * _i,(_building getDir _approach) + 90]) findEmptyPosition [0,4,"B_Soldier_F"];
    private _actor = _group createUnit ["B_Soldier_F",_position,[],0,"NONE"];
    _actor allowDamage false; _actors pushBack _actor;
};
_group setCombatMode "GREEN"; _group setBehaviour "COMBAT"; _group call VCM_fnc_SquadExc;
private _opfor = createGroup [east,true]; _opfor setVariable ["Vcm_Disable",true];
private _enemy = _opfor createUnit ["O_Soldier_F",(_building buildingPos -1) select 0,[],0,"NONE"];
_enemy disableAI "ALL"; _group reveal [_enemy,4];
private _layout = [_building] call VCM_fnc_CQBLayout;
diag_log format ["VCM_CQB_TERRAIN_ROOMS: %1",(_layout select 3) apply {_x apply {(_layout select 0) select _x}}];
private _until = diag_tickTime + 6;
waitUntil {sleep 0.1; count ([_group] call VCM_fnc_TacticalUnits) >= 4 &&
    {([leader _group,_enemy] call VCM_fnc_ContactPosition) isNotEqualTo []} || {diag_tickTime >= _until}};
private _job = [_group,_enemy] spawn VCM_fnc_ClearBuilding;
_until = diag_tickTime + 3;
waitUntil {sleep 0.1; _group getVariable ["VCM_Task",[]] isNotEqualTo [] || {scriptDone _job} || {diag_tickTime >= _until}};
deleteVehicle _enemy;
private _climbed = false;
private _bottom = 1e9;
{_bottom = _bottom min (ATLToASL _x select 2)} forEach (_building buildingPos -1);
_until = diag_tickTime + 220;
waitUntil {
    sleep 0.5;
    if (_actors findIf {_x distance2D _building < 16 && {(getPosASL _x select 2) > _bottom + 2.5}} >= 0) then {_climbed = true};
    scriptDone _job || {diag_tickTime >= _until}
};
private _progress = _group getVariable ["VCM_CQBProgress",[]];
diag_log format ["VCM_CQB_FLOORS: %1 climbed=%2 actors=%3",_progress,_climbed,_actors apply {getPosATL _x}];
[_climbed,"entry team physically climbs to the upper floor"] call _assert;
[scriptDone _job && {_progress param [2,""] == "searched"},"two-floor building finishes a complete mapped room search"] call _assert;
[count (_progress param [5,[]]) == count (_layout select 3),"all rooms on both floors are recorded as searched"] call _assert;
[_progress param [6,[]] isEqualTo [],"native two-floor search has no skipped or blocked room"] call _assert;
[_group getVariable ["VCM_CQBSession",[]] isEqualTo [],"two-floor search releases its live session"] call _assert;
_group setVariable ["Vcm_Disable",true]; sleep 0.5;
{deleteVehicle _x} forEach (_actors + [_enemy]);
deleteGroup _group; deleteGroup _opfor;
