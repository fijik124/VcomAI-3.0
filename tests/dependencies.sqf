/* Run with no mods, or CBA alone, to exercise real missing-dependency startup. */
private _missing = ["cba_main","cba_settings","ace_main","ace_medical","ace_medical_engine"] select {
    !isClass (configFile >> "CfgPatches" >> _x)
};
[_missing isNotEqualTo [],"negative startup fixture omits a required dependency"] call _assert;
[!([] call VCM_fnc_InitSettings),"settings initialization rejects missing dependencies"] call _assert;
private _startup = [] execVM "Vcom\VcomInit.sqf";
sleep 0.25;
[scriptDone _startup,"missing-dependency startup exits without waiting indefinitely"] call _assert;
[!(missionNamespace getVariable ["VCM_SettingsInitialized",false]),"missing dependencies leave settings uninitialized"] call _assert;
[!(missionNamespace getVariable ["VCM_Started",false]) && {!(missionNamespace getVariable ["VCM_ServerReady",false])},
    "missing dependencies do not start the AI runtime"] call _assert;
[!(missionNamespace getVariable ["VCM_CBARegistered",false]),"missing dependencies do not register partial settings"] call _assert;
