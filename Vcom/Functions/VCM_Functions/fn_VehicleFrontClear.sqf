params ["_vehicle",["_distance",18]];
private _origin = getPosATL _vehicle;
private _forward = vectorDir _vehicle;
private _side = side group driver _vehicle;
private _width = 2 + abs (boundingBoxReal _vehicle select 1 select 0);
((_vehicle nearEntities ["Man",_distance + 3]) findIf {
    private _person = _x;
    private _offset = (getPosATL _person) vectorDiff _origin;
    _offset set [2,0];
    private _along = _offset vectorDotProduct _forward;
    private _lateral = vectorMagnitude (_offset vectorDiff (_forward vectorMultiply _along));
    alive _person && {isNull objectParent _person} && {_along > 0} && {_along < _distance} &&
    {_lateral < _width} && {!([_side,side group _person] call BIS_fnc_sideIsEnemy)}
}) < 0
