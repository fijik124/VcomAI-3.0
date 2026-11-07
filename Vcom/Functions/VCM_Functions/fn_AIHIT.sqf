/* Author: Genesis, Freddo. Hit reactions must never create or cancel medical unconsciousness. */
params ["_unit", "_source", "_damage", "_instigator"];
if (!VCM_MEDICALACTIVE || {!VCM_RAGDOLL} || {_damage <= 0.1} ||
    {random 100 >= VCM_RAGDOLLCHC} || {!isNull objectParent _unit} ||
    {lifeState _unit == "INCAPACITATED"} || {_unit getVariable ["VCM_HitStance", ""] != ""}) exitWith {};
private _group = group _unit;
private _run = _group getVariable ["VCM_RunId", []];
if (!([_unit, _group, _run] call VCM_fnc_ActionValid)) exitWith {};
private _stance = unitPos _unit;
_unit setVariable ["VCM_HitStance", _stance, true];
_unit setUnitPos "DOWN";
[_unit, _group, _run, _stance] spawn {
    params ["_unit", "_group", "_run", "_stance"];
    sleep 5;
    if ([_unit, _group, _run] call VCM_fnc_ActionValid && {VCM_MEDICALACTIVE} && {lifeState _unit != "INCAPACITATED"}) then {
        _unit setUnitPos _stance;
        _unit setVariable ["VCM_HitStance", nil, true];
    };
};
