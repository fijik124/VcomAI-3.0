params ["_vehicle"];
private _record = _vehicle getVariable ["VCM_ConvoyControl",[]];
if (!local _vehicle || {_record isEqualTo []}) exitWith {};
if (abs (getForcedSpeed _vehicle - (_record select 2)) < 0.01) then {_vehicle forceSpeed (_record select 1)};
_vehicle setVariable ["VCM_ConvoyControl",nil,true];
_vehicle setVariable ["VCM_ConvoyRecovery",nil];
