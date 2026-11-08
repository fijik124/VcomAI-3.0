/* Restore only state owned by VCOM. Public inventory records survive headless-client handoff. */
params ["_unit", ["_fireOnly", false], ["_inventoryOnly", false]];
if (isNull _unit || {!local _unit}) exitWith {};
private _lock = _unit getVariable ["VCM_FireLock", []];
if (!_inventoryOnly && {_lock isNotEqualTo []}) then {
    _unit setVariable ["VCM_FireLock", nil, true];
    if (_lock param [1, false]) then {_unit enableAI "FIREWEAPON"};
};
if (_fireOnly) exitWith {};
if (!isNil {_unit getVariable "VCM_ThrowBlockUntil"}) then {_unit setVariable ["VCM_ThrowBlockUntil",nil,true]};
private _stored = _unit getVariable ["VCM_StoredGrenades", []];
if (_stored isEqualTo []) exitWith {};
_unit setVariable ["VCM_StoredGrenades", nil, true];
[_unit,_stored] call VCM_fnc_ReturnMagazines;
