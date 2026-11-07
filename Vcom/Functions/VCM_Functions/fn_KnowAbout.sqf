/* Author: Genesis. Knowledge updates may originate only on the server. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params [["_listeners", [], [[]]], ["_target", objNull, [objNull]], ["_amount", 0.1, [0]]];
if (!Vcm_ActivateAI || {isNull _target} || {!alive _target}) exitWith {};
_amount = (_amount max 0) min 0.4;
{
    if (_x isEqualType objNull && {local _x} && {alive _x} && {!isPlayer _x} &&
        {[group _x] call VCM_fnc_GroupEnabled} &&
        {[side group _x, side group _target] call BIS_fnc_sideIsEnemy}) then {
        _x reveal [_target, ((_x knowsAbout _target) + _amount) min 4];
    };
} forEach _listeners;
