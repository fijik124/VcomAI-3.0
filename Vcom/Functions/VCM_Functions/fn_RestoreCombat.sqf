params ["_group"];
if (_group getVariable ["VCM_Task",[]] isEqualTo [] && {_group getVariable ["VCM_BoundState",[]] isEqualTo []}) then {[_group] call VCM_fnc_AttackControl};
if (!local _group) exitWith {};
private _speed = _group getVariable ["VCM_OriginalSpeed", ""];
if (_speed != "") then {
    _group setSpeedMode _speed;
    _group setVariable ["VCM_OriginalSpeed", nil, true];
};
[_group] call VCM_fnc_ClearWaypoints;
