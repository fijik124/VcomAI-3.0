if (missionNamespace getVariable ["VCM_CBARegistered", false]) exitWith {};
if (!(missionNamespace getVariable ["cba_settings_ready",false])) exitWith {};
VCM_CBARegistered = true;
private _settings = [];
private _queue = {
    params ["_name","_type","_title","_group","_value","_global",["_callback",{}]];
    if (_name in ["VCM_Debug","VCM_DEBUGOVERLAY"]) then {
        private _tooltip = if (_name == "VCM_Debug") then {
            "Publishes AI decisions and native state from every AI owner. Clients with the local panel/overlay option enabled can inspect squads in gameplay and Zeus."
        } else {
            "Shows the debugger panel, labels and routes in gameplay and Zeus. Enable AI debugger and telemetry in server/mission settings first. This preference is local; saved false values remain off."
        };
        _title = [_title,_tooltip];
        _callback = {
            if (hasInterface) then {
                if (_thisSetting == "VCM_DEBUGOVERLAY") then {
                    private _previous = missionNamespace getVariable ["VCM_DebugPreviousOverlay",_this];
                    VCM_DebugPreviousOverlay = _this;
                    if (_this && {!_previous} && {missionNamespace getVariable ["VCM_DebugUIReady",false]}) then {
                        VCM_DebugStatusUntil = diag_tickTime + 8;
                    };
                };
                VCM_DebugNextUI = -1;
                [] call VCM_fnc_DebugUI;
            };
        };
    };
    _settings pushBack [_name,_type,_title,["VCOM Edited by Fijik",_group],_value,_global,_callback];
};
{
    _x params ["_name","_type","_title","_default","_minimum","_maximum","_decimals","_global","_group"];
    private _configured = missionNamespace getVariable [_name,_default];
    private _value = if (_type == "CHECKBOX") then {_configured} else {[_minimum,_maximum,_configured,_decimals]};
    [_name,_type,_title,_group,_value,_global] call _queue;
} forEach ([] call VCM_fnc_FeatureSettings);
{
    _x params ["_name", "_title", "_group"];
    [_name, "CHECKBOX", _title, _group, missionNamespace getVariable _name, true] call _queue;
} forEach [
    ["Vcm_ActivateAI", "Vcom Active", "01 General"],
    ["VCM_Debug", "Enable AI debugger and telemetry", "18 Debugger and Telemetry"],
    ["VCM_ARTYENABLE", "AI artillery", "13 Anti-Tank and Artillery"],
    ["VCM_CARGOCHNG", "Manage combat dismounting", "14 Vehicles and Convoys"],
    ["VCM_TURRETUNLOAD", "Allow turret crew dismounting", "14 Vehicles and Convoys"],
    ["VCM_StealVeh", "Use empty vehicles", "14 Vehicles and Convoys"],
    ["VCM_ClassSteal", "Require crew and pilots", "14 Vehicles and Convoys"],
    ["VCM_ADVANCEDMOVEMENT", "Generate tactical waypoints", "03 Movement and Cover"],
    ["VCM_FRMCHANGE", "Change formation", "03 Movement and Cover"],
    ["VCM_SKILLCHANGE", "Apply Vcom skills", "01 General"],
    ["VCM_FIREMOVEMENT", "Coordinated fire and movement", "03 Movement and Cover"],
    ["VCM_COVERSEARCH", "Prefer physical cover during team advances", "03 Movement and Cover"],
    ["VCM_WALLCHECK", "Prevent firing through walls", "09 Fire and Grenade Safety"],
    ["VCM_NOGRENADESINDOORS", "No grenade throws inside barracks", "09 Fire and Grenade Safety"],
    ["VCM_CROSSOWNER_SUPPORT", "Reinforcements across headless clients", "12 Squad Coordination and Reinforcements"],
    ["VCM_TACTICALRETREAT", "Tactical withdrawal", "07 Defense and Withdrawal"],
    ["VCM_REACTIVESUPPRESSION", "Support pressured squadmates", "12 Squad Coordination and Reinforcements"],
    ["VCM_BUILDINGCLEARING", "Building entry and support teams", "08 Building Clearing"],
    ["VCM_COMBINEDARMS", "Infantry and ground vehicle coordination", "14 Vehicles and Convoys"]
];
// Retain the old saved CBA name, mapping its raw boolean value to the runtime setting.
["VCM_ForceSpeed", "CHECKBOX", "Full speed in combat", "03 Movement and Cover", VCM_FullSpeed, true,
    {VCM_FullSpeed = _this}] call _queue;
{
    _x params ["_name", "_title", "_minimum", "_maximum", "_group"];
    [_name, "SLIDER", _title, _group, [_minimum, _maximum, missionNamespace getVariable _name, 0], true] call _queue;
} forEach [
    ["VCM_DISEMBARKRANGE", "Dismount distance", 50, 1000, "14 Vehicles and Convoys"],
    ["VCM_AIDISTANCEVEHPATH", "Vehicle search distance", 0, 1000, "14 Vehicles and Convoys"],
    ["VCM_HEARINGDISTANCE", "Gunfire hearing distance", 0, 10000, "05 Reconnaissance"],
    ["VCM_WARNDIST", "Reinforcement range", 0, 10000, "12 Squad Coordination and Reinforcements"],
    ["VCM_WARNDELAY", "Reinforcement delay", 0, 10000, "12 Squad Coordination and Reinforcements"],
    ["VCM_STATICARMT", "Static weapon occupation time", 0, 10000, "15 Equipment and Resupply"],
    ["VCM_MINECHANCE", "Mine placement chance", 0, 100, "15 Equipment and Resupply"],
    ["VCM_ARTYDELAY", "Artillery request delay", 0, 5000, "13 Anti-Tank and Artillery"],
    ["VCM_AIMagLimit", "Rearm magazine threshold", 2, 10, "15 Equipment and Resupply"],
    ["VCM_BOUNDLENGTH", "Team advance distance (meters)", 10, 40, "03 Movement and Cover"],
    ["VCM_BOUNDSECONDS", "Team advance time limit (seconds)", 5, 60, "03 Movement and Cover"]
];
private _sides = [[west, east, resistance], [west, east], [west], [east], [resistance], [resistance, west], [resistance, east]];
private _labels = ["West, East, Resistance", "West, East", "West", "East", "Resistance", "Resistance, West", "Resistance, East"];
{
    _x params ["_name", "_title", "_group"];
    private _default = _sides find (missionNamespace getVariable _name);
    if (_default < 0) then {_default = _sides pushBack (missionNamespace getVariable _name); _labels pushBack "Custom"};
    [_name, "LIST", _title, _group, [_sides, _labels, _default], true] call _queue;
} forEach [["VCM_SIDEENABLED", "Enabled sides", "01 General"],
    ["VCM_ARTYSIDES", "Artillery sides", "13 Anti-Tank and Artillery"]];

// CBA keeps registration order inside each subcategory. Sort scalar/string keys only;
// the callback CODE values stay in the original registration arguments.
private _order = [];
{
    private _priority = if (_x select 0 == "Vcm_ActivateAI") then {-1} else {parseNumber (_x select 1 != "CHECKBOX")};
    private _title = _x select 2;
    if (_title isEqualType []) then {_title = _title select 0};
    _order pushBack [_x select 3 select 1,_priority,toLower _title,_forEachIndex];
} forEach _settings;
_order sort true;
{(_settings select (_x select 3)) call CBA_fnc_addSetting} forEach _order;
diag_log "VCOM: Registered CBA settings";
