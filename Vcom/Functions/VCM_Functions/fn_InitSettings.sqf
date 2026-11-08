/* CfgFunctions preInit: local code is compiled locally, never received over the network. */
if (missionNamespace getVariable ["VCM_SettingsInitialized", false]) exitWith {};
VCM_SettingsInitialized = true;
[] call compile preprocessFileLineNumbers "Vcom\Functions\VcomAI_DefaultSettings.sqf";
[] call Vcm_Settings;
VCM_ThrowMagazineSet = createHashMapFromArray ((compatibleMagazines "Throw") apply {[_x,true]});
VCM_ThrowInfo = createHashMapFromArray ((compatibleMagazines "Throw") apply {
    private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
    private _config = configFile >> "CfgAmmo" >> _ammo;
    private _lethal = getNumber (_config >> "indirectHit") > 0 || {getNumber (_config >> "explosive") > 0};
    private _smoke = !_lethal && {toLower getText (_config >> "simulation") in ["shotsmoke","shotsmokex"]} &&
        {toLower getText (_config >> "effectsSmoke") find "smoke" >= 0};
    [_x,[_ammo,_lethal,_smoke]]
});
// Capture the allowed setting names/types before reading any user overrides.
VCM_SettingSchema = [];
{
    private _value = missionNamespace getVariable _x;
    VCM_SettingSchema pushBack [_x, typeName _value];
} forEach [
    "Vcm_ActivateAI", "VCM_ARTYENABLE", "VCM_ARTYDELAY", "VCM_ARTYSIDES", "VCM_AIMagLimit",
    "VCM_Debug", "VCM_MINECHANCE", "VCM_SIDEENABLED", "VCM_RAGDOLL", "VCM_RAGDOLLCHC",
    "VCM_FullSpeed", "VCM_HEARINGDISTANCE", "VCM_WARNDIST", "VCM_WARNDELAY", "VCM_STATICARMT",
    "VCM_StealVeh", "VCM_ClassSteal", "VCM_AIDISTANCEVEHPATH", "VCM_ADVANCEDMOVEMENT",
    "VCM_FRMCHANGE", "VCM_SKILLCHANGE", "VCM_USECBASETTINGS", "VCM_CARGOCHNG", "VCM_TURRETUNLOAD",
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
CBAACT = isClass (configFile >> "CfgPatches" >> "cba_main");
// ACE owns damage and unconsciousness whenever its medical component is loaded.
VCM_MEDICALACTIVE = !(isClass (configFile >> "CfgPatches" >> "ace_medical")) &&
    {!(isClass (configFile >> "CfgPatches" >> "ace_medical_engine"))};
VCM_SettingsReady = isServer;
VCM_CBAReady = !CBAACT;
// Register after CBA's own startup; addon preInit can precede its mission namespace initialization.
