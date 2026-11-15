/* Let the ordinary controller select and start recon/defense without any commander point or preset. */
private _scouts = createGroup [west,true];
_scouts setVariable ["VCM_Skilldisable",true];
private _scoutUnits = [];
for "_i" from 0 to 2 do {
    private _soldier = _scouts createUnit ["B_Soldier_F",[6100,6100 + _i * 5,0],[],0,"NONE"];
    _soldier allowDamage false; _scoutUnits pushBack _soldier;
};
_scouts call VCM_fnc_SquadExc;
private _autonomousRecon = [{(_scouts getVariable ["VCM_Task",[]]) param [1,""] == "recon"},15] call _await;
[_autonomousRecon && {[_scouts] call VCM_fnc_Doctrine == "recon"} &&
    {_scouts getVariable ["VCM_Objective",[]] isEqualTo []},"small AI element autonomously chooses and starts reconnaissance without Zeus"] call _assert;
_scouts setVariable ["Vcm_Disable",true];
private _assault = createGroup [west,true];
_assault setVariable ["VCM_Skilldisable",true];
private _assaultUnits = [];
for "_i" from 0 to 5 do {
    private _soldier = _assault createUnit ["B_Soldier_F",[7000,6900 + _i * 4,0],[],0,"NONE"];
    _soldier allowDamage false; _assaultUnits pushBack _soldier;
};
_assault setCombatMode "GREEN";
_assault reveal [_enemy,4];
_assault call VCM_fnc_SquadExc;
private _assaultReady = [{[_assault] call VCM_fnc_Doctrine == "assault"},15] call _await;
[_assaultReady && {_assault getVariable ["VCM_Objective",[]] isEqualTo []},
    "supplied AI squad selects assault from a remembered contact without a preset"] call _assert;
_assault setVariable ["VCM_PeakStrength",8,true];
_assault setVariable ["VCM_AutoRoleAfter",-1];
_assault setVariable ["VCM_NextTactic",0];
private _autonomousDefense = [{(_assault getVariable ["VCM_Task",[]]) param [1,""] == "defend"},15] call _await;
[_autonomousDefense && {[_assault] call VCM_fnc_Doctrine == "defend"} &&
    {_assault getVariable ["VCM_Objective",[]] isEqualTo []},"AI losses trigger autonomous defensive positions without a Zeus marker"] call _assert;
private _authored = _assault addWaypoint [[7050,6900,0],0];
_authored setWaypointName "AUTONOMY_MISSION_PRIORITY";
private _released = [{_assault getVariable ["VCM_Task",[]] isEqualTo []},5] call _await;
[_released && {(waypoints _assault) findIf {waypointName _x == "AUTONOMY_MISSION_PRIORITY"} >= 0},
    "an authored route cancels autonomous defense and remains intact"] call _assert;
_assault setVariable ["Vcm_Disable",true];
sleep 0.5;
{deleteVehicle _x} forEach (_scoutUnits + _assaultUnits);
deleteGroup _scouts; deleteGroup _assault;
