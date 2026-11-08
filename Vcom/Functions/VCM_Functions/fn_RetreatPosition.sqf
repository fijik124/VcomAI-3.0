params ["_unit","_threat",["_reserved",[]]];
private _origin = getPosATL _unit;
private _away = (_unit getDir _threat) + 180;
private _best = [];
private _score = -1e6;
{
    private _position = (_unit getPos [25,_away + _x]) findEmptyPosition [0,3,typeOf _unit];
    if (_position isNotEqualTo [] && {!surfaceIsWater _position} && {(surfaceNormal _position select 2) > 0.75} &&
        {_unit distance2D _position <= 30} && {_position distance2D _threat >= (_unit distance2D _threat) + 10} &&
        {_reserved findIf {_x distance2D _position < 3} < 0}) then {
        private _gain = (_position distance2D _threat) - (_origin distance2D _threat);
        private _candidate = 30 * ([_unit,_position,_threat] call VCM_fnc_CoverProtection) + 0.25 * _gain - 0.1 * (_origin distance2D _position);
        if (_candidate > _score) then {_score = _candidate; _best = _position};
    };
} forEach [0,-30,30,-60,60];
_best
