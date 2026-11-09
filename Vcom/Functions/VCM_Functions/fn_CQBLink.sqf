/* Geometry link with explicit door crossings. Closed doors remain potential, lock-checked edges. */
params ["_building","_from","_to","_doors"];
private _fromASL = ATLToASL _from;
private _delta = (ATLToASL _to) vectorDiff _fromASL;
private _distance = vectorMagnitude _delta;
if (_distance < 0.05 || {abs (_delta select 2) > 3.8} || {abs (_delta select 2) > ((_from distance2D _to) + 0.4)}) exitWith {[false,[]]};
private _crossings = [];
private _horizontal = [_delta select 0,_delta select 1,0];
private _length2 = _horizontal vectorDotProduct _horizontal;
{
    private _door = ATLToASL (_x select 2);
    private _offset = _door vectorDiff _fromASL;
    private _along = if (_length2 > 0.01) then {(_offset vectorDotProduct _horizontal) / _length2} else {-1};
    private _nearest = _fromASL vectorAdd (_delta vectorMultiply ((_along max 0) min 1));
    if (_along > 0 && {_along < 1} && {_door distance2D _nearest < 1.05} && {abs ((_door select 2) - (_nearest select 2)) < 2}) then {_crossings pushBackUnique _forEachIndex};
} forEach _doors;
private _queries = [];
{_queries pushBack [ATLToASL (_from vectorAdd [0,0,_x]),ATLToASL (_to vectorAdd [0,0,_x]),objNull,objNull,true,8,"GEOM","NONE",false]} forEach [0.45,1.25];
private _clear = true;
{
    {
        private _hit = _x;
        private _object = _hit select 3;
        if (isNull _object) then {_object = _hit select 2};
        if (!(_object isKindOf "Man") && {!(_object isKindOf "LandVehicle")}) then {
            private _doorIndex = -1;
            if (_object == _building) then {
                _doorIndex = _doors findIf {
                    private _number = _x select 0;
                    (_hit select 4) findIf {toLower _x == format ["door_%1",_number]} >= 0 ||
                    {(_hit select 0) distance2D (_x select 2) < 1.05 &&
                        {abs ((_hit select 0 select 2) - (ATLToASL (_x select 2) select 2)) < 1.7}}
                };
            };
            if (_doorIndex < 0) then {_clear = false} else {_crossings pushBackUnique _doorIndex};
        };
    } forEach _x;
} forEach (lineIntersectsSurfaces [_queries]);
[_clear,_crossings]
