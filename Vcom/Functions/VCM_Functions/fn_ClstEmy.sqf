/* Closest hostile contact known by this group; always returns OBJECT. */
private _observer = _this;
if !(_observer isEqualType objNull) exitWith {objNull};
if (isNull _observer) exitWith {objNull};
private _group = group _observer;
private _side = side _group;
private _best = objNull;
private _distance = 1e12;
{
    _x params ["_position", "_type", "_targetSide", "_cost", "_target"];
    if (!isNull _target && {alive _target} && {!captive _target} &&
        {!((vehicle _target) isKindOf "Air")} && {[_side, _targetSide] call BIS_fnc_sideIsEnemy} &&
        {_group knowsAbout _target > 0 || {(vehicle _observer) knowsAbout _target > 0}}) then {
        private _candidate = _observer distance2D _position;
        if (_candidate < _distance) then {_distance = _candidate; _best = _target};
    };
} forEach ([_observer] call VCM_fnc_KnownContacts);
_best
