/* Author: Genesis. Vanilla treatment only. ACE Medical owns its own treatment state. */
params ["_group", "_medics"];
if (_group getVariable ["VCM_BoundState", []] isNotEqualTo []) exitWith {};
if (!VCM_MEDICALACTIVE || {!([_group] call VCM_fnc_GroupEnabled)}) exitWith {};
{
    private _patient = _x;
    if (alive _patient && {local _patient} && {!isPlayer _patient} && {damage _patient > 0} &&
        {lifeState _patient != "INCAPACITATED"} && {!(_patient getVariable ["VCM_PatientBusy", false])}) then {
        if !(_patient call VCM_fnc_HealSelf) then {
            private _available = _medics select {
                alive _x && {local _x} && {!isPlayer _x} && {_x != _patient} &&
                {lifeState _x != "INCAPACITATED"} && {!(_x getVariable ["VCM_MBUSY", false])} && {_x distance _patient <= 75}
            };
            if (count _available > 0) then {
                private _medic = [_available, _patient, true, "MedicalHandler"] call VCM_fnc_ClstObj;
                // Reserve before spawning; another patient cannot select the same medic.
                _medic setVariable ["VCM_MBUSY", true];
                _patient setVariable ["VCM_PatientBusy", true];
                [_medic, _patient, _group getVariable ["VCM_RunId", []]] spawn VCM_fnc_MedicHeal;
            };
        };
    };
} forEach units _group;
