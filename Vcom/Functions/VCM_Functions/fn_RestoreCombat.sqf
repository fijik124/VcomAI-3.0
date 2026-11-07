params ["_group"];
if (!local _group) exitWith {};
private _speed = _group getVariable ["VCM_OriginalSpeed", ""];
if (_speed != "") then {
    _group setSpeedMode _speed;
    _group setVariable ["VCM_OriginalSpeed", nil, true];
};
[_group] call VCM_fnc_ClearWaypoints;
