/* Choose a short physical detour; never teleport, bypass PATH or extend a task's deadline. */
params ["_unit","_goal","_run","_key","_attempt"];
if (!VCM_UNSTUCK || {_attempt > floor VCM_UNSTUCKTRIES} ||
    {!([_unit,group _unit,_run] call VCM_fnc_ActionValid)} || {!(_unit checkAIFeature "PATH")} ||
    {group _unit getVariable ["VCM_NOFLANK",false]} || {(waypoints group _unit) findIf {(_x select 1) > 0} >= 0} ||
    {!isNull objectParent _unit}) exitWith {[]};
private _reservation = _unit getVariable ["VCM_TaskKey",[]];
if (_reservation isEqualTo []) then {_reservation = _unit getVariable ["VCM_BoundKey",[]]};
if (_key isEqualTo [] || {!(_key isEqualTo _reservation)}) exitWith {[]};
private _result = [];
private _direction = _unit getDir _goal;
private _sign = [-1,1] select (_attempt mod 2 == 0);
{
    private _point = (_unit getPos [VCM_UNSTUCKRADIUS,_direction + _x * _sign]) findEmptyPosition [0,2,typeOf _unit];
    if (_point isNotEqualTo [] && {!surfaceIsWater _point} && {(surfaceNormal _point select 2) > 0.75} &&
        {_unit distance2D _point >= 2} && {_unit distance2D _point <= VCM_UNSTUCKRADIUS + 3} &&
        {[eyePos _unit,ATLToASL (_point vectorAdd [0,0,1]),_unit] call VCM_fnc_PhysicalFireLane}) exitWith {_result = _point};
} forEach [60,100,-60,-100];
_unit setVariable ["VCM_LastRecovery",[_attempt,_result,_goal,time],VCM_Debug];
[group _unit,"recovery",format ["%1 attempt %2 destination %3",_unit,_attempt,_result]] call VCM_fnc_DebugTrace;
_result
