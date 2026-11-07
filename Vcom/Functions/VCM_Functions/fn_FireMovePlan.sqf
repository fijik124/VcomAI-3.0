/* No orders are issued here. Machine gunners get first support-team slots. */
params ["_leader"];
private _group = group _leader;
private _run = _group getVariable ["VCM_RunId", []];
if (!([_group, _run] call VCM_fnc_FireMoveReady) ||
    {_group getVariable ["VCM_BoundState", []] isNotEqualTo []} ||
    {diag_tickTime < (_group getVariable ["VCM_NextBound", -1])}) exitWith {[]};
private _enemy = _leader call VCM_fnc_ClstEmy;
if (isNull _enemy || {!([_group, _run, _enemy] call VCM_fnc_FireMoveReady)}) exitWith {[]};
private _position = [_leader, _enemy] call VCM_fnc_ContactPosition;
if (_position isEqualTo []) exitWith {[]};
private _distance = _leader distance2D _position;
if (_distance < 60 || {_distance > 400}) exitWith {[]};
private _units = (units _group) select {[_x, _group, _run] call VCM_fnc_BoundUnitReady};
if (count _units < 4) exitWith {[]};
private _gunners = _units select {((primaryWeapon _x call BIS_fnc_itemType) param [1, ""]) == "MachineGun"};
private _ordered = _gunners + (_units - _gunners);
_ordered = _ordered select [0, 8];
private _support = [];
private _maneuver = [];
{
    if (_forEachIndex mod 2 == 0) then {_support pushBack _x} else {_maneuver pushBack _x};
} forEach _ordered;
[_enemy, _position, _support, _maneuver, _run]
