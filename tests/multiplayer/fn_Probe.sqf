/* Only the server may request a client inspection. No executable payloads. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params ["_label", ["_groups", []]];
private _states = _groups apply {
    private _group = _x;
    [local _group, groupOwner _group, {_x isEqualTo _group} count VcmAI_ActiveList,
        _group getVariable ["VCM_RunId", []], _group getVariable ["VCM_GarrisonBusy", false],
        (units _group) apply {
            [local _x, _x getVariable ["VCM_Handlers", []], _x getVariable ["VCM_BoundKey", []],
                _x getVariable ["VCM_MoveKey", []], _x checkAIFeature "PATH", backpack _x,
                _x getVariable ["VCM_StoredGrenades",[]],magazines _x,_x checkAIFeature "FIREWEAPON",
                _x getVariable ["VCM_TaskKey",[]],_x checkAIFeature "TARGET",_x checkAIFeature "FSM",
                _x getVariable ["VCM_CivilianState",[]],_x getVariable ["VCM_SurrenderState",[]],
                unitPos _x,getForcedSpeed _x,captive _x,_x checkAIFeature "AUTOTARGET"]
        },[_group getVariable ["VCM_Doctrine","default"],_group getVariable ["VCM_Objective",[]],
            _group getVariable ["VCM_ObjectiveContext",[]],_group getVariable ["VCM_DangerMemory",[]],
            (units _group) apply {[_x getVariable ["VCM_ReconROE",[]],_x getVariable ["VCM_NightState",[]],_x checkAIFeature "LIGHTS"]}]]
};
private _moduleChecks = (missionNamespace getVariable ["VCM_TestAddonChecks",[]]) apply {
    _x params ["_patch","_category","_directory","_functions"];
    isClass (configFile >> "CfgPatches" >> _patch) &&
    {getText (configFile >> "CfgFunctions" >> "VCOM" >> _category >> "file") == _directory} &&
    {_functions findIf {isNil _x} < 0}
};
private _payload = [didJIP, VCM_SettingsReady, call VCM_fnc_SettingsSnapshot, _states,_moduleChecks,
    missionNamespace getVariable ["VCM_CommandPointRegistry",[]]];
if (isServer) then {[2, objNull, _label, _payload] call VCM_test_fnc_Report} else {
    [clientOwner, player, _label, _payload] remoteExecCall ["VCM_test_fnc_Report", 2];
};
