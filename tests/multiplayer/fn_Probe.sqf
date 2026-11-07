/* Only the server may request a client inspection. No executable payloads. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params ["_label", ["_groups", []]];
private _states = _groups apply {
    private _group = _x;
    [local _group, groupOwner _group, {_x isEqualTo _group} count VcmAI_ActiveList,
        _group getVariable ["VCM_RunId", []], _group getVariable ["VCM_GarrisonBusy", false],
        (units _group) apply {
            [local _x, _x getVariable ["VCM_Handlers", []], _x getVariable ["VCM_BoundKey", []],
                _x getVariable ["VCM_MoveKey", []], _x checkAIFeature "PATH", backpack _x]
        }]
};
private _payload = [didJIP, VCM_SettingsReady, call VCM_fnc_SettingsSnapshot, _states];
if (isServer) then {[2, objNull, _label, _payload] call VCM_test_fnc_Report} else {
    [clientOwner, player, _label, _payload] remoteExecCall ["VCM_test_fnc_Report", 2];
};
