/* Public pair records permit a new owner to release an interrupted drag. Never heal or wake the casualty. */
params ["_group",["_key",[]],["_unit",objNull]];
private _pair = _group getVariable ["VCM_Evacuation",[]];
if (_pair isEqualTo [] && {!isNull _unit}) then {
    private _patientState = _unit getVariable ["VCM_EvacPatient",[]];
    private _rescuerState = _unit getVariable ["VCM_EvacRescuer",[]];
    if (count _patientState == 4) then {_pair = [_patientState select 1,_patientState select 2,_unit,_patientState select 3]};
    if (count _rescuerState == 4) then {_pair = [_rescuerState select 1,_unit,_rescuerState select 2,_rescuerState select 3]};
};
if (_pair isEqualTo [] || {_key isNotEqualTo [] && {!((_pair select 0) isEqualTo _key)}}) exitWith {};
_pair params ["_savedKey","_rescuer","_patient","_speed"];
if (local _patient && {((_patient getVariable ["VCM_EvacPatient",[]]) param [1,[]]) isEqualTo _savedKey}) then {
    if (attachedTo _patient == _rescuer) then {detach _patient};
    if (((_patient getVariable ["VCM_EvacPatient",[]]) param [1,[]]) isEqualTo _savedKey) then {
        _patient setVariable ["VCM_EvacPatient",nil,true];
        _patient setVariable ["VCM_PatientBusy",false,true];
    };
};
if (local _rescuer && {((_rescuer getVariable ["VCM_EvacRescuer",[]]) param [1,[]]) isEqualTo _savedKey}) then {
    if (getForcedSpeed _rescuer == 1) then {_rescuer forceSpeed _speed};
    if (((_rescuer getVariable ["VCM_EvacRescuer",[]]) param [1,[]]) isEqualTo _savedKey) then {_rescuer setVariable ["VCM_EvacRescuer",nil,true]};
};
if (local _group) then {_group setVariable ["VCM_Evacuation",nil,true]};
[_group,"evac-release",format ["%1",_patient]] call VCM_fnc_DebugTrace;
