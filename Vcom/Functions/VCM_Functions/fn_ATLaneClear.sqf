params ["_unit","_target","_point"];
if (!([_unit,_point,_target] call VCM_fnc_FireLaneClear)) exitWith {false};
private _behind = _unit getPos [15,(_unit getDir _point) + 180];
if (!([eyePos _unit,ATLToASL (_behind vectorAdd [0,0,1]),_unit,_target] call VCM_fnc_PhysicalFireLane)) exitWith {false};
private _origin = getPosATL _unit;
private _direction = vectorNormalized (_behind vectorDiff _origin);
((_unit nearEntities ["Man",18]) findIf {
    private _offset = (getPosATL _x) vectorDiff _origin;
    private _along = _offset vectorDotProduct _direction;
    _x != _unit && {alive _x} && {_along > 0} && {_along < 15} &&
    {vectorMagnitude (_offset vectorDiff (_direction vectorMultiply _along)) < 5} &&
    {!([side group _unit,side group _x] call BIS_fnc_sideIsEnemy)}
}) < 0
