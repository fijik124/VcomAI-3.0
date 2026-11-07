/* Native pathfinding chooses the route; reject water, steep ground and close assaults. */
params ["_unit", "_target", "_length", ["_reserved", []]];
if (isNull _unit || {!local _unit} || {count _target != 3}) exitWith {[]};
private _distance = _unit distance2D _target;
private _step = ((_length max 10) min 40) min (_distance - 50);
if (_step < 5) exitWith {[]};
private _bearing = _unit getDir _target;
private _preferred = _unit getPos [_step, _bearing];
private _best = [];
private _bestScore = -1e6;
// Eight candidates per mover, evaluated once per phase rather than in a frame loop.
{
    _x params ["_forward", "_lateral"];
    private _candidate = _unit getPos [_step + _forward, _bearing];
    _candidate = _candidate getPos [abs _lateral, _bearing + ([-90,90] select (_lateral >= 0))];
    private _position = _candidate findEmptyPosition [0, 2, typeOf _unit];
    if (_position isNotEqualTo [] && {!surfaceIsWater _position} &&
        {_unit distance2D _position >= 5} && {_unit distance2D _position <= ((_step + 8) min 46)} &&
        {_position distance2D _target >= 50} && {_position distance2D _target <= _distance - 4} &&
        {abs (_position select 2) < 0.5} && {(surfaceNormal _position select 2) >= 0.75} &&
        {_reserved findIf {_x distance2D _position < 3} < 0}) then {
        private _protection = 0;
        if (VCM_COVERSEARCH) then {_protection = [_unit, _position, _target] call VCM_fnc_CoverProtection};
        private _score = 30 * _protection - 0.5 * (_position distance2D _preferred) - 0.1 * (_unit distance2D _position);
        if (_score > _bestScore) then {_bestScore = _score; _best = _position};
    };
} forEach [[0,0], [0,-4], [0,4], [0,-8], [0,8], [-4,0], [-4,-4], [-4,4]];
_best
