/* Author: Genesis. Rate-limit reports locally and validate them on the server. */
params ["_unit", "_weapon"];
if (!local _unit || {!alive _unit} || {!Vcm_ActivateAI} || {_weapon in ["Put", "Throw"]}) exitWith {};
if (time < (_unit getVariable ["VCM_FTH", -10]) + 10) exitWith {};
_unit setVariable ["VCM_FTH", time];
if (isServer) then {[_unit, _weapon] call VCM_fnc_HearingRelay} else {
    [_unit, _weapon] remoteExecCall ["VCM_fnc_HearingRelay", 2];
};
