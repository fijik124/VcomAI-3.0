/* Require overhead building geometry and an interior point, rather than proximity to a building center. */
params ["_unit",["_fresh",false]];
if (isNull _unit || {!isNull objectParent _unit}) exitWith {false};
private _start = (getPosASL _unit) vectorAdd [0,0,0.9];
private _cached = _unit getVariable ["VCM_IndoorCache",[]];
if (!_fresh && {_cached isNotEqualTo []} && {diag_tickTime < (_cached select 0)} &&
    {_start distance (_cached select 1) < 0.5} && {(_cached select 3) isEqualTo VCM_BARRACKSCLASSES}) exitWith {_cached select 2};
private _hits = lineIntersectsSurfaces [_start, _start vectorAdd [0,0,20], _unit, objNull, true, 4, "GEOM", "NONE"];
private _inside = _hits findIf {
    private _building = _x select 3;
    if (isNull _building) then {_building = _x select 2};
    private _matches = !isNull _building && {_building isKindOf "House"} && {
        (toLower typeOf _building find "barracks") >= 0 ||
        {VCM_BARRACKSCLASSES findIf {_x isEqualType "" && {_building isKindOf _x}} >= 0}
    };
    if (_matches) then {
        private _bounds = boundingBoxReal _building;
        private _point = _building worldToModel (ASLToAGL _start);
        private _minimum = _bounds select 0;
        private _maximum = _bounds select 1;
        _matches = (_point select 0) > (_minimum select 0) && {(_point select 0) < (_maximum select 0)} &&
            {(_point select 1) > (_minimum select 1)} && {(_point select 1) < (_maximum select 1)};
    };
    _matches
} >= 0;
_unit setVariable ["VCM_IndoorCache",[diag_tickTime + 0.75,_start,_inside,+VCM_BARRACKSCLASSES]];
_inside
