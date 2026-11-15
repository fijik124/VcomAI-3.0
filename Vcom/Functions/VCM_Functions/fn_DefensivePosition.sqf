/* Sample physical cover around an assigned center, with separated destinations and danger avoidance. */
params ["_unit","_center","_watch",["_radius",15],["_reserved",[]]];
private _best = [];
private _bestScore = -1e9;
private _direction = _center getDir _watch;
{
    _x params ["_fraction","_angle"];
    private _candidate = _center getPos [_radius * _fraction,_direction + _angle];
    private _point = _candidate findEmptyPosition [0,2,typeOf _unit];
    if (_point isNotEqualTo [] && {!surfaceIsWater _point} && {(surfaceNormal _point select 2) >= 0.75} &&
        {abs (_point select 2) < 1} && {_point distance2D _center <= _radius + 2} &&
        {_reserved findIf {_x distance2D _point < 3} < 0}) then {
        private _score = 30 * ([_unit,_point,_watch] call VCM_fnc_CoverProtection) -
            0.25 * (_unit distance2D _point) - ([group _unit,_point] call VCM_fnc_DangerPenalty);
        if (_score > _bestScore) then {_bestScore = _score; _best = _point};
    };
} forEach [[0,0],[0.35,90],[0.35,-90],[0.7,90],[0.7,-90],[0.7,180],[1,135],[1,-135],[1,180]];
_best
