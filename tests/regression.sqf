/* Run in the generated VR mission. Results are written to the server RPT. */
if (!isServer) exitWith {};
waitUntil {sleep 0.1; missionNamespace getVariable ["VCM_ServerReady", false]};
diag_log format ["VCM_TEST_ENV: %1; CBA=%2; vanillaMedical=%3", productVersion, CBAACT, VCM_MEDICALACTIVE];
VCM_TestFailures = 0;
VCM_TestCount = 0;
private _assert = {
    params ["_condition", "_name"];
    VCM_TestCount = VCM_TestCount + 1;
    if (!_condition) then {VCM_TestFailures = VCM_TestFailures + 1};
    diag_log format ["VCM_TEST_%1: %2", ["FAIL", "PASS"] select _condition, _name];
};
Vcm_ActivateAI = false;
[] call compile preprocessFileLineNumbers "addon-layout.sqf";
sleep 0.5;
private _group = createGroup [west, true];
private _unit = _group createUnit ["B_Soldier_F", [1000,1000,0], [], 0, "NONE"];
_unit enableSimulationGlobal false;
private _opposition = createGroup [east, true];
private _enemy = _opposition createUnit ["O_Soldier_F", [4000,4000,0], [], 0, "NONE"];
_enemy enableSimulationGlobal false;
_opposition setVariable ["Vcm_Disable", true];
Vcm_ActivateAI = true;
[!([grpNull] call VCM_fnc_GroupEnabled), "null group rejected"] call _assert;
_group setVariable ["Vcm_Disable", true];
[!([_group] call VCM_fnc_GroupEnabled), "disabled group rejected"] call _assert;
_group setVariable ["Vcm_Disable", false];
[[_group] call VCM_fnc_GroupEnabled, "eligible local group accepted"] call _assert;
[isNull (_unit call VCM_fnc_ClstEmy), "undetected enemy is not selected"] call _assert;
_group reveal [_enemy, 4];
sleep 0.2;
[(_unit call VCM_fnc_ClstEmy) isEqualTo _enemy, "revealed hostile selected"] call _assert;
[count ([_unit, _enemy] call VCM_fnc_ContactPosition) == 3, "contact has a perceived position"] call _assert;
[isNull (objNull call VCM_fnc_ClstEmy), "null observer returns objNull"] call _assert;

private _missionWaypoint = _group addWaypoint [[1100,1000,0], 0];
_missionWaypoint setWaypointName "AUTHORED";
_missionWaypoint setWaypointType "MOVE";
private _original = [waypointName _missionWaypoint, waypointPosition _missionWaypoint, waypointType _missionWaypoint];
[_group, [1200,1000,0]] call VCM_fnc_AddWaypoint;
[_group] call VCM_fnc_ClearWaypoints;
private _kept = (waypoints _group) select {waypointName _x == "AUTHORED"};
[count _kept == 1, "authored waypoint survives VCOM cleanup"] call _assert;
if (count _kept == 1) then {
    [[waypointName (_kept select 0), waypointPosition (_kept select 0), waypointType (_kept select 0)] isEqualTo _original,
        "authored waypoint content unchanged"] call _assert;
};
private _before = count waypoints _group;
[_unit] call VCM_fnc_FlankMove;
[count waypoints _group == _before, "flanking respects mission orders"] call _assert;

_group setVariable ["VCM_Skilldisable", true];
_unit setSkill ["aimingAccuracy", 0.19];
_group call VCM_AIDIFSET;
[abs ((_unit skill "aimingAccuracy") - 0.19) < 0.001, "skill opt-out respected"] call _assert;
_group setSpeedMode "LIMITED";
_group call VCM_fnc_SquadExc;
sleep 0.2;
private _run = _group getVariable ["VCM_RunId", []];
private _handlers = _unit getVariable ["VCM_Handlers", []];
[_group] call VCM_fnc_BindUnits;
[(_unit getVariable ["VCM_Handlers", []]) isEqualTo _handlers, "handler binding is idempotent"] call _assert;
_group call VCM_fnc_SquadExc;
[{_x isEqualTo _group} count VcmAI_ActiveList == 1, "one controller per group"] call _assert;
_group setVariable ["VCM_OriginalSpeed", "LIMITED", true];
_group setSpeedMode "FULL";
Vcm_ActivateAI = false;
sleep 1;
[!(_group in VcmAI_ActiveList), "global disable stops existing controller"] call _assert;
[isNil {_unit getVariable "VCM_Handlers"}, "controller exit removes handlers"] call _assert;
[speedMode _group == "LIMITED", "controller exit restores speed"] call _assert;
[!([_unit, _group, _run] call VCM_fnc_ActionValid), "old action token cancelled"] call _assert;
Vcm_ActivateAI = true;
_group call VCM_fnc_SquadExc;
sleep 0.2;
[!(_run isEqualTo (_group getVariable ["VCM_RunId", []])), "reenabling creates a fresh run token"] call _assert;
[!([_unit, _group, _run] call VCM_fnc_ActionValid), "old action cannot resume a new run"] call _assert;

[( ["8Rnd_82mm_Mo_shells"] call VCM_fnc_ArtilleryAmmo) == "HE", "HE classified through config"] call _assert;
[( ["8Rnd_82mm_Mo_Smoke_white"] call VCM_fnc_ArtilleryAmmo) == "SMOKE", "smoke classified through config"] call _assert;
[( ["VCM_NONEXISTENT"] call VCM_fnc_ArtilleryAmmo) == "IGNORE", "unknown ammunition ignored"] call _assert;
VCM_ARTYAMMOOVERRIDES = [["VCM_TEST_AMMO", "HE"]];
[( ["VCM_TEST_AMMO"] call VCM_fnc_ArtilleryAmmo) == "HE", "mod ammunition override honored"] call _assert;
VCM_ARTYAMMOOVERRIDES = [];
[!([west, getPosATL _unit, 100] call VCM_fnc_ArtillerySafe), "friendly soldier vetoes artillery"] call _assert;
[[west, [8000,8000,0], 100] call VCM_fnc_ArtillerySafe, "empty impact area accepted"] call _assert;
[[[]] call VCM_fnc_ApplySettings isEqualTo false, "settings reject untrusted local execution"] call _assert;
private _snapshot = call VCM_fnc_SettingsSnapshot;
[[_snapshot] call VCM_fnc_ValidateSettings, "valid settings snapshot accepted"] call _assert;
private _invalid = call VCM_fnc_SettingsSnapshot;
_invalid set [0, ["Vcm_ActivateAI", 42]];
[!([_invalid] call VCM_fnc_ValidateSettings), "wrong setting type rejected"] call _assert;
_invalid set [0, ["VCM_UntrustedVariable", true]];
[!([_invalid] call VCM_fnc_ValidateSettings), "unknown setting rejected"] call _assert;
_invalid = call VCM_fnc_SettingsSnapshot;
_invalid set [0, +(_invalid select 1)];
[!([_invalid] call VCM_fnc_ValidateSettings), "duplicate settings rejected"] call _assert;
_invalid = call VCM_fnc_SettingsSnapshot;
private _arrayIndex = _invalid findIf {(_x select 0) == "VCM_AIDIFA"};
_invalid set [_arrayIndex, ["VCM_AIDIFA", [[{hint "must never execute"}]]]];
[!([_invalid] call VCM_fnc_ValidateSettings), "nested executable code rejected"] call _assert;
[_snapshot isEqualTo (call VCM_fnc_SettingsSnapshot), "rejected snapshots do not mutate settings"] call _assert;
[(VCM_SIDEENABLED findIf {!(_x isEqualType west)}) < 0, "side settings are flat side arrays"] call _assert;
private _medical = VCM_MEDICALACTIVE;
VCM_MEDICALACTIVE = false;
_unit addItem "FirstAidKit";
[!(_unit call VCM_fnc_HealSelf), "ACE adapter blocks vanilla treatment"] call _assert;
VCM_MEDICALACTIVE = _medical;

// No compatible building must remain a bounded no-op and preserve existing PATH state.
private _hold = _group addWaypoint [[2000,2000,0], 0];
_hold setWaypointType "HOLD";
_group setCurrentWaypoint _hold;
private _pathBefore = _unit checkAIFeature "PATH";
private _garrison = _group spawn VCM_fnc_Garrison;
sleep 0.5;
[scriptDone _garrison, "garrison without a building exits"] call _assert;
[(_unit checkAIFeature "PATH") isEqualTo _pathBefore, "garrison preserves pathfinding state"] call _assert;

private _building = createVehicle ["Land_i_House_Big_01_V1_F", [1010,1010,0], [], 0, "NONE"];
private _buildingHold = _group addWaypoint [[1010,1010,0], 0];
_buildingHold setWaypointType "HOLD";
_group setCurrentWaypoint _buildingHold;
private _buildingGarrison = _group spawn VCM_fnc_Garrison;
sleep 0.5;
_buildingHold setWaypointType "MOVE";
sleep 0.75;
[scriptDone _buildingGarrison, "garrison cancels after HOLD changes"] call _assert;
[(_unit checkAIFeature "PATH") isEqualTo _pathBefore, "garrison cancellation preserves PATH"] call _assert;
deleteVehicle _building;

VCM_MINECHANCE = 100;
_unit addMagazine "APERSMine_Range_Mag";
private _mineAmmo = getText (configFile >> "CfgMagazines" >> "APERSMine_Range_Mag" >> "ammo");
[_unit, [_mineAmmo, "APERSMine_Range_Mag"]] call VCM_fnc_MinePlant;
[count VCOM_MINEARRAY == 1, "native mine registered"] call _assert;
if (count VCOM_MINEARRAY == 1) then {
    private _mine = VCOM_MINEARRAY select 0 select 0;
    [simulationEnabled _mine, "native mine simulation remains enabled"] call _assert;
    deleteVehicle _mine;
    sleep 0.2; // Engine deletion completes on a later simulation frame.
};
[] call VCM_fnc_MineMonitor;
[VCOM_MINEARRAY isEqualTo [], "dead mine registry entries pruned"] call _assert;

_unit addBackpack "B_HMG_01_weapon_F";
_group reveal [_enemy, 4];
private _deployRun = _group getVariable ["VCM_RunId", []];
private _deployment = [_unit, backpack _unit, _deployRun] spawn VCM_fnc_DeployStatic;
sleep 0.25;
[_unit getVariable ["VCM_DeployBusy", false], "static deployment starts for the current run"] call _assert;
Vcm_ActivateAI = false;
sleep 4;
[scriptDone _deployment, "static deployment cancels after global disable"] call _assert;
[backpack _unit == "B_HMG_01_weapon_F", "cancelled deployment preserves the carried weapon"] call _assert;
[count (nearestObjects [_unit, ["StaticWeapon"], 10]) == 0, "cancelled deployment removes its empty temporary weapon"] call _assert;
removeBackpackGlobal _unit;
Vcm_ActivateAI = true;
_group call VCM_fnc_SquadExc;
sleep 0.2;

// Let the actual FSM traverse combat/rearm/vehicle checks with simulation enabled.
_unit enableSimulationGlobal true;
_unit setBehaviour "COMBAT";
sleep 20;
[_group in VcmAI_ActiveList, "combat controller remains active"] call _assert;

[] call compile preprocessFileLineNumbers "cover.sqf";
[] call compile preprocessFileLineNumbers "safety.sqf";
[] call compile preprocessFileLineNumbers "fire-movement.sqf";
[] call compile preprocessFileLineNumbers "tactics.sqf";
[] call compile preprocessFileLineNumbers "vehicle.sqf";

Vcm_ActivateAI = false;
sleep 0.5;
deleteVehicle _unit;
deleteVehicle _enemy;
deleteGroup _group;
deleteGroup _opposition;
diag_log format ["VCM_TEST_DONE: %1 checks, %2 failures", VCM_TestCount, VCM_TestFailures];
