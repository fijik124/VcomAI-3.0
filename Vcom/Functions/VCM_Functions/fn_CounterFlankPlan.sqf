/* React only to native remembered contacts, comparing bearings against the last established threat axis. */
params ["_group"];
if (!VCM_COUNTERFLANK || {!([_group] call VCM_fnc_GroupEnabled)} ||
    {_group getVariable ["VCM_Task",[]] isNotEqualTo []} || {_group getVariable ["VCM_NOFLANK",false]} ||
    {(waypoints _group) findIf {(_x select 1) > 0} >= 0} ||
    {diag_tickTime < (_group getVariable ["VCM_FlankAfter",-1])}) exitWith {[]};
private _leader = leader _group;
private _contacts = ([_leader] call VCM_fnc_KnownContacts) select {
    private _target = _x select 4;
    !isNull _target && {alive _target} && {!captive _target} &&
    {[side _group,_x select 2] call BIS_fnc_sideIsEnemy} && {_group knowsAbout _target >= 2} &&
    {_leader distance2D (_x select 0) <= VCM_FLANKRANGE}
};
if (_contacts isEqualTo []) exitWith {[]};
private _axis = _group getVariable ["VCM_ThreatAxis",[]];
if (_axis isEqualTo [] || {time - (_axis select 1) > 90}) exitWith {
    _group setVariable ["VCM_ThreatAxis",[_leader getDir (_contacts select 0 select 0),time],true]; []
};
private _flank = _contacts findIf {
    private _difference = abs (((_leader getDir (_x select 0)) - (_axis select 0) + 540) mod 360 - 180);
    _difference >= VCM_FLANKANGLE
};
if (_flank < 0) exitWith {[]};
private _bound = _group getVariable ["VCM_BoundState",[]];
if (_bound isNotEqualTo []) then {[_group,_bound select 0,"flank-threat"] call VCM_fnc_EndFireMove};
if (!([_group] call VCM_fnc_TacticalReady)) exitWith {[]};
private _contact = _contacts select _flank;
private _units = ([_group] call VCM_fnc_TacticalUnits) select {!(_x getUnitTrait "Medic")};
if (count _units < 3) exitWith {[]};
private _movers = _units select [(count _units - 2) max 1,2];
private _support = (_units - _movers) select [0,4];
private _reserved = _support apply {getPosATL _x};
private _positions = [];
{
    private _point = [_x,getPosATL _leader,_contact select 0,VCM_FLANKSTEP,_reserved] call VCM_fnc_DefensivePosition;
    _positions pushBack _point;
    if (_point isNotEqualTo []) then {_reserved pushBack _point};
} forEach _movers;
if (_positions findIf {_x isEqualTo []} >= 0) exitWith {[]};
[_contact select 4,_contact select 0,_support,_movers,_positions]
