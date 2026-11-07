/* Short native suppression pulses expire even if the controller loses ownership. */
params ["_units", "_group", "_run", "_position", "_enemy"];
private _count = 0;
{
    if ([_x, _group, _run] call VCM_fnc_BoundUnitReady &&
        {[_x, _position, _enemy] call VCM_fnc_FireLaneClear}) then {
        _x doWatch (_position vectorAdd [0,0,1]);
        _x suppressFor 2;
        _count = _count + 1;
    } else {
        if (local _x && {alive _x} && {!isPlayer _x}) then {_x suppressFor 0};
    };
} forEach _units;
_count
