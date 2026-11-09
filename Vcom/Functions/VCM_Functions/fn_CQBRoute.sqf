/* Shortest current route. Door locks are read live, never cached in the layout. */
params ["_building","_layout","_position","_goal"];
_layout params ["_points","_edges","_roomIds","_rooms","_doors"];
private _available = {
    params ["_ids"];
    _ids findIf {
        private _door = _doors select _x;
        _building animationSourcePhase (_door select 1) < 0.65 &&
        {!((_building getVariable [format ["bis_disabled_Door_%1",_door select 0],0]) in [0,false])}
    } < 0
};
private _candidates = [];
{_candidates pushBack [_position distance (_x select 0),_forEachIndex]} forEach _points;
_candidates sort true;
private _start = -1;
{
    if (_x select 0 < 8) then {
        private _link = [_building,_position,_points select (_x select 1) select 0,_doors] call VCM_fnc_CQBLink;
        if (_link select 0 && {[_link select 1] call _available}) exitWith {_start = _x select 1};
    };
    if (_start >= 0) exitWith {};
} forEach (_candidates select [0,16]);
if (_start < 0 || {_goal < 0} || {_goal >= count _points}) exitWith {[]};
private _cost = _points apply {1e9};
private _previous = _points apply {-1};
private _open = [_start];
_cost set [_start,0];
while {_open isNotEqualTo []} do {
    private _best = 0;
    {if (_cost select _x < (_cost select (_open select _best))) then {_best = _forEachIndex}} forEach _open;
    private _node = _open deleteAt _best;
    if (_node == _goal) exitWith {};
    {
        _x params ["_next","_doorIds","_length"];
        private _score = (_cost select _node) + _length;
        if (_score < (_cost select _next) && {[_doorIds] call _available}) then {
            _cost set [_next,_score]; _previous set [_next,_node]; _open pushBackUnique _next;
        };
    } forEach (_edges select _node);
};
if (_cost select _goal >= 1e9) exitWith {[]};
private _route = [_goal];
private _node = _goal;
while {_node != _start && {count _route <= count _points}} do {
    _node = _previous select _node;
    if (_node < 0) exitWith {};
    _route pushBack _node;
};
reverse _route;
_route
