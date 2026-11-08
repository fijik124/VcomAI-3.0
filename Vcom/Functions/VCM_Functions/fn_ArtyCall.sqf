/* Author: Genesis. Fire only supported ammunition at a known hostile contact. */
params ["_callGroup", "_enemyGroup", ["_knowledge", 0]];
if (!VCM_ARTYENABLE || {!([_callGroup] call VCM_fnc_GroupEnabled)}) exitWith {};
private _leader = leader _callGroup;
private _enemy = _leader call VCM_fnc_ClstEmy;
if (isNull _enemy || {group _enemy != _enemyGroup}) exitWith {};
private _target = [_leader, _enemy] call VCM_fnc_ContactPosition;
if (_target isEqualTo []) exitWith {};
private _request = [_callGroup,_enemy,_target,"artillery",player,_callGroup knowsAbout _enemy];
if (isServer) then {_request call VCM_fnc_SupportRequest} else {_request remoteExecCall ["VCM_fnc_SupportRequest",2]};
