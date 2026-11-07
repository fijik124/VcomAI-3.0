/* Score nearby physical cover against a remembered threat position, without inspecting an enemy object. */
params ["_unit", "_position", "_threat"];
if (isNull _unit || {count _position != 3} || {count _threat != 3}) exitWith {0};
private _threatASL = ATLToASL (_threat vectorAdd [0,0,1.5]);
private _protection = 0;
{
    _x params ["_height", "_weight"];
    private _start = ATLToASL (_position vectorAdd [0,0,_height]);
    private _direction = _threatASL vectorDiff _start;
    // Distant obstructions and moving soldiers/vehicles are not dependable local cover.
    private _end = _start vectorAdd ((vectorNormalized _direction) vectorMultiply ((vectorMagnitude _direction) min 12));
    private _blocked = terrainIntersectASL [_start, _end];
    if (!_blocked) then {
        private _hits = lineIntersectsSurfaces [_start, _end, _unit, objNull, true, 4, "FIRE", "NONE"];
        _blocked = _hits findIf {
            private _object = _x select 3;
            if (isNull _object) then {_object = _x select 2};
            isNull _object || {!(_object isKindOf "AllVehicles")}
        } >= 0;
    };
    if (_blocked) then {_protection = _protection + _weight};
} forEach [[0.35,0.25], [0.9,0.5], [1.6,0.25]];
_protection
