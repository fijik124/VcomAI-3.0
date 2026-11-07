if (missionNamespace getVariable ["VCM_CBARegistered", false]) exitWith {};
if (!CBAACT || {!VCM_USECBASETTINGS}) exitWith {};
VCM_CBARegistered = true;
{
    _x params ["_name", "_title"];
    [_name, "CHECKBOX", _title, "VCOM SETTINGS", missionNamespace getVariable _name, true] call CBA_fnc_addSetting;
} forEach [
    ["Vcm_ActivateAI", "Vcom Active"], ["VCM_Debug", "Debug logging"],
    ["VCM_ARTYENABLE", "AI artillery"], ["VCM_CARGOCHNG", "Manage combat dismounting"],
    ["VCM_TURRETUNLOAD", "Allow turret crew dismounting"], ["VCM_StealVeh", "Use empty vehicles"],
    ["VCM_ClassSteal", "Require crew and pilots"], ["VCM_ADVANCEDMOVEMENT", "Generate tactical waypoints"],
    ["VCM_FRMCHANGE", "Change formation"], ["VCM_SKILLCHANGE", "Apply Vcom skills"],
    ["VCM_FIREMOVEMENT", "Coordinated fire and movement"],
    ["VCM_COVERSEARCH", "Prefer physical cover during team advances"],
    ["VCM_RAGDOLL", "React to hits (stance only)"]
];
// Retain the old saved CBA name, mapping its raw boolean value to the runtime setting.
["VCM_ForceSpeed", "CHECKBOX", "Full speed in combat", "VCOM SETTINGS", VCM_FullSpeed, true,
    {VCM_FullSpeed = _this}] call CBA_fnc_addSetting;
{
    _x params ["_name", "_title", "_minimum", "_maximum"];
    [_name, "SLIDER", _title, "VCOM SETTINGS", [_minimum, _maximum, missionNamespace getVariable _name, 0], true] call CBA_fnc_addSetting;
} forEach [
    ["VCM_DISEMBARKRANGE", "Dismount distance", 50, 1000],
    ["VCM_AIDISTANCEVEHPATH", "Vehicle search distance", 0, 1000],
    ["VCM_RAGDOLLCHC", "Hit reaction chance", 0, 100],
    ["VCM_HEARINGDISTANCE", "Gunfire hearing distance", 0, 10000],
    ["VCM_WARNDIST", "Reinforcement range", 0, 10000],
    ["VCM_WARNDELAY", "Reinforcement delay", 0, 10000],
    ["VCM_STATICARMT", "Static weapon occupation time", 0, 10000],
    ["VCM_MINECHANCE", "Mine placement chance", 0, 100],
    ["VCM_ARTYDELAY", "Artillery request delay", 0, 5000],
    ["VCM_AIMagLimit", "Rearm magazine threshold", 2, 10],
    ["VCM_BOUNDLENGTH", "Team advance distance (meters)", 10, 40],
    ["VCM_BOUNDSECONDS", "Team advance time limit (seconds)", 5, 15]
];
private _sides = [[west, east, resistance], [west, east], [west], [east], [resistance], [resistance, west], [resistance, east]];
private _labels = ["West, East, Resistance", "West, East", "West", "East", "Resistance", "Resistance, West", "Resistance, East"];
{
    _x params ["_name", "_title"];
    private _default = _sides find (missionNamespace getVariable _name);
    if (_default < 0) then {_default = _sides pushBack (missionNamespace getVariable _name); _labels pushBack "Custom"};
    [_name, "LIST", _title, "VCOM SETTINGS", [_sides, _labels, _default], true] call CBA_fnc_addSetting;
} forEach [["VCM_SIDEENABLED", "Enabled sides"], ["VCM_ARTYSIDES", "Artillery sides"]];
diag_log "VCOM: Registered CBA settings";
