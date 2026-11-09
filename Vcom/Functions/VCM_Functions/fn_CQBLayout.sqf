/* Cached floor/door graph. The planner runs in a separate scheduled job, never in the safety watcher. */
params ["_building"];
if (isNull _building || {!alive _building}) exitWith {[]};
private _signature = [getPosWorld _building,vectorDir _building,vectorUp _building,damage _building];
private _cached = _building getVariable ["VCM_CQBLayout",[]];
if (_cached isNotEqualTo [] && {(_cached select 6) isEqualTo _signature} &&
    {(_building getVariable ["VCM_CQBLayoutLimit",-1]) == floor VCM_CQBNODES}) exitWith {_cached};
private _points = [];
private _notes = [];
private _doors = [_building] call VCM_fnc_CQBDoors;
if (count _doors > 48) then {_doors resize 48; _notes pushBack "door-limit"};
private _limit = floor VCM_CQBNODES;
private _append = {
    params ["_position","_inside",["_priority",1]];
    if (_points findIf {(_x select 0) distance _position < 0.65} < 0) then {
        if (count _points < _limit) then {_points pushBack [_position,_inside,_priority]} else {_notes pushBackUnique "node-limit"};
    };
};
private _floors = [];
{
    private _floor = [_building,_x] call VCM_fnc_CQBFloor;
    if (_floor isNotEqualTo []) then {
        [_floor select 0,true,0] call _append;
        private _height = (_building worldToModel (_floor select 0)) select 2;
        if (_floors findIf {abs (_x - _height) < 0.8} < 0) then {_floors pushBack _height};
    };
} forEach (_building buildingPos -1);
private _bounds = boundingBoxReal _building;
private _low = _bounds select 0;
private _high = _bounds select 1;
private _width = (_high select 0) - (_low select 0);
private _depth = (_high select 1) - (_low select 1);
if (_width > 80 || {_depth > 80} || {count _floors > 8}) then {_notes pushBack "geometry-limit"} else {
    {
        private _height = _x;
        for "_px" from ((_low select 0) + 0.8) to ((_high select 0) - 0.5) step 2.4 do {
            for "_py" from ((_low select 1) + 0.8) to ((_high select 1) - 0.5) step 2.4 do {
                if (count _points < _limit) then {
                    private _floor = [_building,_building modelToWorld [_px,_py,_height]] call VCM_fnc_CQBFloor;
                    if (_floor isNotEqualTo []) then {[_floor select 0,true] call _append};
                } else {_notes pushBackUnique "node-limit"};
            };
        };
    } forEach _floors;
};
{
    private _door = _x select 2;
    // Probe both sides in several directions; no model animation is changed during mapping.
    {
        private _probe = _door getPos [1.2,getDir _building + _x];
        _probe set [2,(_door select 2) - 0.8];
        private _floor = [_building,_probe,false] call VCM_fnc_CQBFloor;
        if (_floor isNotEqualTo []) then {[_floor select 0,_floor select 1,2] call _append};
    } forEach [0,45,90,135,180,225,270,315];
} forEach _doors;
for "_exit" from 0 to 15 do {
    private _point = _building buildingExit _exit;
    if (_point isNotEqualTo [0,0,0]) then {[_point,false,3] call _append};
};
private _edges = _points apply {[]};
{
    private _index = _forEachIndex;
    private _from = _x select 0;
    private _near = [];
    {if (_forEachIndex != _index && {_from distance (_x select 0) < 5.8}) then {_near pushBack [_from distance (_x select 0),_forEachIndex]}} forEach _points;
    _near sort true;
    {
        private _other = _x select 1;
        if ((_edges select _index) findIf {_x select 0 == _other} < 0) then {
            private _link = [_building,_from,_points select _other select 0,_doors] call VCM_fnc_CQBLink;
            if (_link select 0) then {
                (_edges select _index) pushBack [_other,_link select 1,_x select 0];
                (_edges select _other) pushBack [_index,_link select 1,_x select 0];
            };
        };
    } forEach (_near select [0,10]);
} forEach _points;
private _roomIds = _points apply {-1};
private _rooms = [];
{
    private _seed = _forEachIndex;
    if (_x select 1 && {_roomIds select _seed == -1}) then {
        private _room = count _rooms;
        private _nodes = [];
        private _queue = [_seed];
        _roomIds set [_seed,_room];
        while {_queue isNotEqualTo []} do {
            private _node = _queue deleteAt 0;
            _nodes pushBack _node;
            {
                _x params ["_next","_doorIds"];
                if (_doorIds isEqualTo [] && {_points select _next select 1} && {_roomIds select _next == -1} &&
                    {abs ((ATLToASL (_points select _seed select 0) select 2) - (ATLToASL (_points select _next select 0) select 2)) < 0.8}) then {
                    _roomIds set [_next,_room]; _queue pushBack _next;
                };
            } forEach (_edges select _node);
        };
        // Door probes connect routes; they do not create extra search rooms inside a door leaf or threshold.
        private _searchNodes = _nodes select {(_points select _x select 2) < 2};
        if (_searchNodes isEqualTo []) then {
            {_roomIds set [_x,-2]} forEach _nodes;
        } else {
            _rooms pushBack _searchNodes;
        };
    };
} forEach _points;
private _layout = [_points,_edges,_roomIds,_rooms,_doors,_notes,_signature];
if (!isNull _building && {_signature isEqualTo [getPosWorld _building,vectorDir _building,vectorUp _building,damage _building]}) then {
    _building setVariable ["VCM_CQBLayout",_layout];
    _building setVariable ["VCM_CQBLayoutLimit",floor VCM_CQBNODES];
    // A long campaign must not retain a geometry graph for every building ever encountered.
    private _registry = (missionNamespace getVariable ["VCM_CQBLayouts",[]]) select {!isNull _x && {_x != _building}};
    _registry pushBack _building;
    while {count _registry > 16} do {
        private _old = _registry deleteAt 0;
        _old setVariable ["VCM_CQBLayout",nil];
        _old setVariable ["VCM_CQBLayoutLimit",nil];
    };
    VCM_CQBLayouts = _registry;
};
_layout
