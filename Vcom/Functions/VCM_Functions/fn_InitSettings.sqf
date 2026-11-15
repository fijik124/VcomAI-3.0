/* CfgFunctions preInit: local code is compiled locally, never received over the network. */
if (missionNamespace getVariable ["VCM_SettingsInitialized", false]) exitWith {true};
// Mission-script installs have no CfgPatches dependency enforcement.
private _missing = ["cba_main", "cba_settings", "ace_main", "ace_medical", "ace_medical_engine"] select {
    !isClass (configFile >> "CfgPatches" >> _x)
};
if (_missing isNotEqualTo []) exitWith {
    diag_log format ["VCOM ERROR: Required addons missing: %1. Load CBA_A3 and ACE, including ACE Medical, on every machine. VCOM will not start.", _missing];
    false
};
VCM_SettingsInitialized = true;
[] call compile preprocessFileLineNumbers "Vcom\Functions\VcomAI_DefaultSettings.sqf";
[] call Vcm_Settings;
// New controls use the shared descriptors even when an older advanced userconfig is retained.
{
    if (isNil (_x select 0)) then {missionNamespace setVariable [_x select 0,_x select 3]};
} forEach ([] call VCM_fnc_FeatureSettings);
VCM_ThrowMagazineSet = createHashMapFromArray ((compatibleMagazines "Throw") apply {[_x,true]});
VCM_ThrowInfo = createHashMapFromArray ((compatibleMagazines "Throw") apply {
    private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
    private _config = configFile >> "CfgAmmo" >> _ammo;
    private _lethal = getNumber (_config >> "indirectHit") > 0 || {getNumber (_config >> "explosive") > 0};
    private _smoke = !_lethal && {toLower getText (_config >> "simulation") in ["shotsmoke","shotsmokex"]} &&
        {toLower getText (_config >> "effectsSmoke") find "smoke" >= 0};
    private _flare = !_lethal && {toLower _x find "handflare" >= 0 || {toLower _ammo find "handflare" >= 0}};
    [_x,[_ammo,_lethal,_smoke,_flare]]
});
// Capture the allowed setting names/types before reading any user overrides.
VCM_SettingSchema = [];
{
    private _value = missionNamespace getVariable _x;
    VCM_SettingSchema pushBack [_x, typeName _value];
} forEach [
    "Vcm_ActivateAI", "VCM_ARTYENABLE", "VCM_ARTYDELAY", "VCM_ARTYSIDES", "VCM_AIMagLimit",
    "VCM_Debug", "VCM_MINECHANCE", "VCM_SIDEENABLED",
    "VCM_FullSpeed", "VCM_HEARINGDISTANCE", "VCM_WARNDIST", "VCM_WARNDELAY", "VCM_STATICARMT",
    "VCM_StealVeh", "VCM_ClassSteal", "VCM_AIDISTANCEVEHPATH", "VCM_ADVANCEDMOVEMENT",
    "VCM_FRMCHANGE", "VCM_SKILLCHANGE", "VCM_CARGOCHNG", "VCM_TURRETUNLOAD",
    "VCM_DISEMBARKRANGE", "VCM_AIDIFA", "VCM_AIDIFWEST", "VCM_AIDIFEAST", "VCM_AIDIFRESISTANCE",
    "VCM_CLASSNAMESPECIFIC", "VCM_SIDESPECIFICSKILL", "VCM_SKILL_CLASSNAMES", "VCM_ARTYAMMOOVERRIDES",
    "VCM_FIREMOVEMENT", "VCM_BOUNDLENGTH", "VCM_BOUNDSECONDS", "VCM_COVERSEARCH",
    "VCM_WALLCHECK", "VCM_NOGRENADESINDOORS", "VCM_BARRACKSCLASSES", "VCM_CROSSOWNER_SUPPORT",
    "VCM_TACTICALRETREAT", "VCM_REACTIVESUPPRESSION", "VCM_BUILDINGCLEARING", "VCM_COMBINEDARMS"
];
{
    if (_x select 7) then {VCM_SettingSchema pushBack [_x select 0,typeName (_x select 3)]};
} forEach ([] call VCM_fnc_FeatureSettings);
if (isServer && {isFilePatchingEnabled}) then {
    if (loadFile "\userconfig\VCOM_AI\AISettingsV3.hpp" != "") then {
        [] call compile preprocessFileLineNumbers "\userconfig\VCOM_AI\AISettingsV3.hpp";
        [] call Vcm_Settings;
    };
};
VCM_SettingsReady = isServer;
true
