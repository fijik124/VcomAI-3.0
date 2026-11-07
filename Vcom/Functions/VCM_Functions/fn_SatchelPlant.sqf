/* Author: Genesis. Bounded approach and detonation; no forced unconsciousness or AI feature changes. */
params ["_unit", "_satchelArray"];
private _group = group _unit;
if (_group getVariable ["VCM_BoundState", []] isNotEqualTo []) exitWith {};
private _run = _group getVariable ["VCM_RunId", []];
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {count _satchelArray < 2}) exitWith {};
_satchelArray params ["_ammo", "_magazine"];
if (!(_magazine in magazines _unit)) exitWith {};
private _enemy = _unit call VCM_fnc_ClstEmy;
if (isNull _enemy) exitWith {};
private _position = [_unit, _enemy] call VCM_fnc_ContactPosition;
if (_position isEqualTo [] || {_unit distance2D _position > 200}) exitWith {};
private _buildings = nearestObjects [_position, ["House", "Building"], 25];
if (_buildings isEqualTo []) exitWith {};
private _building = _buildings select 0;
private _approach = _building getPos [7, _building getDir _unit];
if (!([_unit, _approach, 45] call VCM_fnc_MoveTo)) exitWith {};
if (!([_unit, _group, _run] call VCM_fnc_ActionValid) || {!(_magazine in magazines _unit)}) exitWith {};
private _class = [_ammo] call VCM_fnc_MineClass;
if (_class == "") exitWith {};
private _charge = createMine [_class, getPosATL _unit, [], 0];
if (isNull _charge) exitWith {};
_unit removeMagazine _magazine;
[_unit, "AinvPknlMstpSnonWnonDnon_Putdown_AmovPknlMstpSnonWnonDnon"] remoteExecCall ["VCM_fnc_PlayAnimation", 0];
private _withdraw = _position getPos [70, _position getDir _unit];
[_unit, _withdraw, 30] call VCM_fnc_MoveTo;
private _deadline = diag_tickTime + 60;
waitUntil {
    sleep 1;
    !([_unit, _group, _run] call VCM_fnc_ActionValid) || {isNull _charge} ||
    {diag_tickTime >= _deadline} || {[side _group, getPosATL _charge, 50] call VCM_fnc_ArtillerySafe}
};
if ([_unit, _group, _run] call VCM_fnc_ActionValid && {!isNull _charge} &&
    {[side _group, getPosATL _charge, 50] call VCM_fnc_ArtillerySafe}) then {_charge setDamage 1};
if ([_unit, _group, _run] call VCM_fnc_ActionValid && {_unit != leader _group}) then {_unit doFollow leader _group};
