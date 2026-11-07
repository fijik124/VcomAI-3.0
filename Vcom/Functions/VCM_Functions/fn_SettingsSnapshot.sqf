/* Server-only settings data; runtime arrays and CODE never cross the network. */
private _clone = {
    params ["_value"];
    if (_value isEqualType []) exitWith {_value apply {[_x] call _clone}};
    _value
};
VCM_SettingSchema apply {[_x select 0, [missionNamespace getVariable (_x select 0)] call _clone]}
