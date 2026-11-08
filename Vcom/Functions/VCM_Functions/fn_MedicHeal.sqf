/* Author: Genesis. Let the engine apply treatment and consume supplies. */
params ["_medic", "_patient", "_run"];
private _group = group _medic;
if (VCM_MEDICALACTIVE && {[_medic, _group, _run] call VCM_fnc_ActionValid} && {alive _patient}) then {
    private _arrived = [_medic, getPosATL _patient, 40, {alive _patient && {VCM_MEDICALACTIVE}}] call VCM_fnc_MoveTo;
    if (_arrived && {_medic distance _patient < 4} && {alive _patient} && {VCM_MEDICALACTIVE}) then {
        _medic action ["HealSoldier", _patient];
        sleep 5;
    };
};
if (_run isEqualTo (_group getVariable ["VCM_RunId", []])) then {
    _medic setVariable ["VCM_MBUSY", false];
    _patient setVariable ["VCM_PatientBusy", false];
    if ([_medic, _group, _run] call VCM_fnc_CanFollow) then {_medic doFollow leader _group};
};
