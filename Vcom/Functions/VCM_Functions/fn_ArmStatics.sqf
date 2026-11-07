/* Author: Genesis. Bounded static occupation; never take over an occupied weapon. */
private _group = _this;
if (_group getVariable ["VCM_BoundState", []] isNotEqualTo []) exitWith {};
if (!([_group] call VCM_fnc_GroupEnabled)) exitWith {};
private _units = (units _group) select {alive _x && {local _x} && {!isPlayer _x} && {isNull objectParent _x}};
private _weapons = (nearestObjects [leader _group, ["StaticWeapon"], 150]) select {alive _x && {isNull assignedGunner _x} && {isNull gunner _x}};
private _run = _group getVariable ["VCM_RunId", []];
{
    if (_units isEqualTo []) exitWith {};
    private _unit = _units deleteAt 0;
    [_unit, _x, _run] spawn {
        params ["_unit", "_weapon", "_run"];
        private _group = group _unit;
        if (!([_unit, _group, _run] call VCM_fnc_ActionValid)) exitWith {};
        if ([_unit, getPosATL _weapon, 30, {alive _weapon && {isNull gunner _weapon}}] call VCM_fnc_MoveTo) then {
            if (!isNull gunner _weapon) exitWith {};
            _unit assignAsGunner _weapon;
            [_unit] orderGetIn true;
            private _deadline = diag_tickTime + (VCM_STATICARMT max 10);
            waitUntil {
                sleep 1;
                !([_unit, _group, _run] call VCM_fnc_ActionValid) || {!alive _weapon} ||
                {diag_tickTime >= _deadline} || {_unit distance2D leader _group > 500}
            };
            if (local _unit && {alive _unit} && {!isPlayer _unit}) then {
                unassignVehicle _unit;
                _unit leaveVehicle _weapon;
                doGetOut _unit;
            };
        };
    };
} forEach _weapons;
