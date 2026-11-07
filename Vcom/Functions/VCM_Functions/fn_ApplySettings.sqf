if (!isRemoteExecuted || {remoteExecutedOwner != 2} || {isServer}) exitWith {false};
params [["_settings", [], [[]]]];
if (!([_settings] call VCM_fnc_ValidateSettings)) exitWith {false};
{missionNamespace setVariable _x} forEach _settings;
VCM_SettingsReady = true;
true
