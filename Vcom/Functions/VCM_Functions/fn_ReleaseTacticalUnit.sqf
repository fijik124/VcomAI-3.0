params ["_unit","_key"];
if (!local _unit || {!((_unit getVariable ["VCM_TaskKey",[]]) isEqualTo _key)}) exitWith {};
if (((_unit getVariable ["VCM_MovementControl",[]]) param [0,[]]) isEqualTo _key) then {[_unit] call VCM_fnc_MovementControl};
_unit setVariable ["VCM_TaskKey",nil,true];
_unit setVariable ["VCM_TaskRole",nil,true];
if ((_unit getVariable ["VCM_CQBMoveKey",[]]) isEqualTo _key) then {_unit setVariable ["VCM_CQBMoveKey",nil]};
if (!isNil {_unit getVariable "VCM_CQBSector"}) then {_unit setVariable ["VCM_CQBSector",nil,true]};
if (alive _unit && {!isPlayer _unit}) then {
    _unit suppressFor 0;
    _unit doWatch objNull;
    if (_unit != leader group _unit) then {_unit doFollow leader group _unit} else {
        if ((waypoints group _unit) findIf {(_x select 1) > 0} < 0) then {doStop _unit};
    };
};
