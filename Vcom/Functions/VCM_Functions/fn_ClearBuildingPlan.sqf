/* Select a building containing the remembered contact, then split entry and outside support roles. */
params ["_group","_enemy"];
if (!VCM_BUILDINGCLEARING || {!([_group] call VCM_fnc_TacticalReady)} || {isNull _enemy} ||
    {diag_tickTime < (_group getVariable ["VCM_ClearAfter",-1])}) exitWith {[]};
private _contact = [leader _group,_enemy] call VCM_fnc_ContactPosition;
if (_contact isEqualTo [] || {leader _group distance2D _contact > 80}) exitWith {[]};
private _buildings = (nearestObjects [_contact,["House"],25]) select {
    private _point = _x worldToModel _contact;
    private _bounds = boundingBoxReal _x;
    private _low = _bounds select 0;
    private _high = _bounds select 1;
    count (_x buildingPos -1) >= 4 && {(_point select 0) > (_low select 0)} &&
        {(_point select 0) < (_high select 0)} && {(_point select 1) > (_low select 1)} && {(_point select 1) < (_high select 1)}
};
if (_buildings isEqualTo []) exitWith {[]};
private _building = _buildings select 0;
private _units = ([_group] call VCM_fnc_TacticalUnits) select {!(_x getUnitTrait "Medic")};
if (count _units < 4) exitWith {[]};
_units = [_units,[],{private _type = [primaryWeapon _x] call BIS_fnc_itemType; [1,0] select ((_type param [1,""]) == "MachineGun")},"ASCEND"] call BIS_fnc_sortBy;
private _support = _units select [0,2];
private _entryTeam = (_units - _support) select [0,4];
private _exits = [];
for "_index" from 0 to 7 do {
    private _exit = _building buildingExit _index;
    if (_exit isNotEqualTo [0,0,0]) then {_exits pushBackUnique _exit};
};
_exits = [_exits,[],{_x distance2D leader _group},"ASCEND"] call BIS_fnc_sortBy;
private _entrance = _exits param [0,_building getPos [8,_building getDir leader _group]];
private _outward = _building getDir _entrance;
private _bounds = boundingBoxReal _building;
private _extent = (vectorMagnitude (_bounds select 0)) max (vectorMagnitude (_bounds select 1));
private _stage = _building getPos [_extent + 4,_outward];
private _stages = [];
{
    private _position = (_stage getPos [2 + 6 * _forEachIndex,_outward + 90]) findEmptyPosition [0,2,typeOf _x];
    _stages pushBack _position;
} forEach _entryTeam;
if (_stages findIf {_x isEqualTo [] || {surfaceIsWater _x}} >= 0) exitWith {[]};
private _rooms = [(_building buildingPos -1),[],{_x distance _contact},"ASCEND"] call BIS_fnc_sortBy;
private _destinations = [];
{
    private _point = _x;
    if (_destinations findIf {_x distance _point < 2} < 0) then {_destinations pushBack _point};
    if (count _destinations >= count _entryTeam) exitWith {};
} forEach _rooms;
if (count _destinations < count _entryTeam) exitWith {[]};
private _phases = [
    [_support,_entryTeam,_stages,20,_entrance],
    [_support,_entryTeam,_destinations,VCM_CQBSECONDS,_entrance]
];
if (VCM_CQBSECTORS) then {
    private _route = [(_building buildingPos -1),[],{_x distance _entrance},"ASCEND"] call BIS_fnc_sortBy;
    private _unique = [];
    {private _point = _x; if (_unique findIf {_x distance _point < 2} < 0) then {_unique pushBack _point}} forEach _route;
    _unique = _unique select [0,(floor VCM_CQBROOMS) max count _entryTeam];
    if (count _unique < count _entryTeam) exitWith {_phases = []};
    _phases resize 1;
    {
        private _entry = _x;
        private _point = _unique select _forEachIndex;
        _phases pushBack [_support + (_entryTeam - [_entry]),[_entry],[_point],VCM_CQBSECONDS,_entrance];
        _entry setVariable ["VCM_CQBSector",[_building,_forEachIndex,_point],true];
    } forEach _entryTeam;
    for "_room" from count _entryTeam to (count _unique - 1) do {
        private _entry = _entryTeam select (_room mod count _entryTeam);
        _phases pushBack [_support + (_entryTeam - [_entry]),[_entry],[_unique select _room],VCM_CQBSECONDS,_unique select _room];
    };
    _group setVariable ["VCM_ClearRoute",_unique,true];
};
if (_phases isEqualTo []) exitWith {[]};
[_building,_support,_entryTeam,_entrance,_phases,_contact]
