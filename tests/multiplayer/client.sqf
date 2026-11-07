if (isServer || {hasInterface}) exitWith {};
waitUntil {sleep 0.1; !isNull player && {missionNamespace getVariable ["VCM_SettingsReady", false]} &&
    {missionNamespace getVariable ["VCM_Started", false]} && {VCM_CBAReady}};
sleep 2;
["joined"] call VCM_test_fnc_Probe;
// Attempt an actual forged settings RPC. The product receiver must reject HC-originated data.
private _snapshot = call VCM_fnc_SettingsSnapshot;
private _forged = call VCM_fnc_SettingsSnapshot;
private _index = _forged findIf {(_x select 0) == "VCM_WARNDIST"};
_forged set [_index, ["VCM_WARNDIST", 9999]];
[_forged] remoteExecCall ["VCM_fnc_ApplySettings", clientOwner];
sleep 0.5;
[clientOwner, player, "forged", (call VCM_fnc_SettingsSnapshot) isEqualTo _snapshot] remoteExecCall ["VCM_test_fnc_Report", 2];
private _expected = VCM_WARNDIST;
VCM_WARNDIST = 1;
VCM_SettingsReady = false;
[player] remoteExecCall ["VCM_fnc_RequestSettings", 2];
private _deadline = diag_tickTime + 5;
waitUntil {sleep 0.1; VCM_SettingsReady || {diag_tickTime > _deadline}};
[clientOwner, player, "requested", VCM_SettingsReady && {VCM_WARNDIST == _expected}] remoteExecCall ["VCM_test_fnc_Report", 2];
