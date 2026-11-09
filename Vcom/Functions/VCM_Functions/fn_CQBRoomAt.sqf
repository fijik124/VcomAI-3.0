/* Confirm the observer's room on the same floor without seeing through walls or across a doorway. */
params ["_building","_layout","_position"];
_layout params ["_points","_edges","_roomIds","_rooms","_doors"];
private _near = [];
{
    private _point = _x select 0;
    if (_x select 1 && {_roomIds select _forEachIndex >= 0} && {_position distance2D _point < 3} && {abs ((ATLToASL _position select 2) - (ATLToASL _point select 2)) < 0.8}) then {
        _near pushBack [_position distance2D _point,_forEachIndex];
    };
} forEach _points;
_near sort true;
private _room = -1;
{
    _x params ["_distance","_node"];
    private _link = if (_distance < 0.15) then {[true,[]]} else {[_building,_position,_points select _node select 0,_doors] call VCM_fnc_CQBLink};
    if (_link select 0 && {_link select 1 isEqualTo []}) exitWith {_room = _roomIds select _node};
} forEach (_near select [0,16]);
_room
