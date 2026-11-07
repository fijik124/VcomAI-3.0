/* Veto scripted suppression across nearby allies/civilians or obstructed sight lines. */
params ["_unit", "_position", ["_enemy", objNull]];
if (!local _unit || {!alive _unit}) exitWith {false};
private _start = eyePos _unit;
private _end = ATLToASL (_position vectorAdd [0,0,1]);
if ([_unit, "VIEW", _enemy] checkVisibility [_start, _end] < 0.2) exitWith {false};
private _origin = getPosATL _unit;
private _vector = [(_position select 0) - (_origin select 0), (_position select 1) - (_origin select 1), 0];
private _lengthSquared = _vector vectorDotProduct _vector;
if (_lengthSquared < 1) exitWith {false};
private _side = side group _unit;
((_unit nearEntities [["Man", "LandVehicle"], (sqrt _lengthSquared) + 15]) findIf {
    private _friendly = _x;
    private _blocked = false;
    if (_friendly != _unit && {alive _friendly} && {!([_side, side _friendly] call BIS_fnc_sideIsEnemy)}) then {
        private _offset = (getPosATL _friendly) vectorDiff _origin;
        _offset set [2, 0];
        private _along = (_offset vectorDotProduct _vector) / _lengthSquared;
        private _closest = _origin vectorAdd (_vector vectorMultiply ((_along max 0) min 1));
        _blocked = (_along > 0 && {_along < 1} && {_friendly distance2D _closest < 4}) ||
            {_friendly distance2D _position < 12};
    };
    _blocked
}) < 0
