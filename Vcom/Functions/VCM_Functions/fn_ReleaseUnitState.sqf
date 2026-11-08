/* Restore only VCOM-owned state when binding, disabling or handing an AI to a human. */
params ["_unit"];
if (!local _unit) exitWith {};
[_unit] call VCM_fnc_RestoreSafety;
[_unit] call VCM_fnc_MovementControl;
private _at = _unit getVariable ["VCM_ATWeapon",[]];
if (_at isNotEqualTo []) then {
    if (!([_unit] call VCM_fnc_HumanControlled) && {_at select 1 != ""}) then {_unit selectWeapon (_at select 1)};
    _unit setVariable ["VCM_ATWeapon",nil,true];
};
private _evac = _unit getVariable ["VCM_EvacPatient",[]];
if (_evac isEqualTo []) then {_evac = _unit getVariable ["VCM_EvacRescuer",[]]};
if (_evac isNotEqualTo []) then {[_evac select 0,_evac select 1,_unit] call VCM_fnc_EvacRelease};
private _vehicle = vehicle _unit;
if (_unit == _vehicle || {_unit == driver _vehicle}) then {[_vehicle] call VCM_fnc_ConvoyRelease};
