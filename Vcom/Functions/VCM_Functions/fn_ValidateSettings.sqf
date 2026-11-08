/* Validate the entire snapshot before the receiver mutates any setting. */
params [["_settings", [], [[]]]];
if (count _settings != count VCM_SettingSchema) exitWith {false};
private _valid = true;
private _seen = [];
private _features = [] call VCM_fnc_FeatureSettings;
private _dataOnly = {
    params ["_value", ["_depth", 0]];
    if (_depth > 8) exitWith {false};
    if (_value isEqualType 0) exitWith {finite _value};
    if (_value isEqualType []) exitWith {
        count _value <= 512 && {_value findIf {isNil {_x} || {!([_x, _depth + 1] call _dataOnly)}} < 0}
    };
    typeName _value in ["BOOL", "SCALAR", "STRING", "SIDE"]
};
{
    if !(_x isEqualType [] && {count _x == 2}) exitWith {_valid = false};
    if (isNil {_x select 0} || {isNil {_x select 1}}) exitWith {_valid = false};
    _x params ["_name", "_value"];
    if !(_name isEqualType "") exitWith {_valid = false};
    private _index = VCM_SettingSchema findIf {(_x select 0) isEqualTo _name};
    if (_index < 0 || {_name in _seen}) exitWith {_valid = false};
    if (typeName _value != (VCM_SettingSchema select _index select 1) || {!([_value] call _dataOnly)}) exitWith {_valid = false};
    private _feature = _features findIf {(_x select 0) == _name};
    if (_feature >= 0 && {_value isEqualType 0} &&
        {_value < (_features select _feature select 4) || {_value > (_features select _feature select 5)}}) exitWith {_valid = false};
    _seen pushBack _name;
} forEach _settings;
_valid
