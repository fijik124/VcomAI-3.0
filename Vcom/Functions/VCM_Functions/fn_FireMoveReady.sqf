/* Shared startup/cancellation checks. Authored routes and engagement rules take priority. */
params ["_group", "_run", ["_enemy", objNull]];
if (!([_group] call VCM_fnc_GroupEnabled) || {_run isEqualTo []} ||
    {!(_run isEqualTo (_group getVariable ["VCM_RunId", []]))} ||
    {!VCM_FIREMOVEMENT} || {!VCM_ADVANCEDMOVEMENT} ||
    {_group getVariable ["VCM_NOFLANK", false]} || {_group getVariable ["VCM_GarrisonBusy", false]} ||
    {_group getVariable ["VCM_MOVE2SUP", false]} || {behaviour leader _group != "COMBAT"} ||
    {!simulationEnabled leader _group} || {!(combatMode _group in ["YELLOW", "RED"])}) exitWith {false};
private _names = _group getVariable ["VCM_WaypointNames", []];
if ((waypoints _group) findIf {(_x select 1) > 0 && {!(waypointName _x in _names)}} >= 0) exitWith {false};
if (!isNull _enemy) exitWith {
    alive _enemy && {!captive _enemy} && {_enemy isKindOf "Man"} && {isNull objectParent _enemy} &&
    {[side _group, side group _enemy] call BIS_fnc_sideIsEnemy} && {_group knowsAbout _enemy >= 2}
};
true
