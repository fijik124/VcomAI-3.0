params ["_unit", "_key"];
if (!local _unit || {!(_key isEqualTo (_unit getVariable ["VCM_BoundKey", []]))}) exitWith {};
if (((_unit getVariable ["VCM_MovementControl",[]]) param [0,[]]) isEqualTo _key) then {[_unit] call VCM_fnc_MovementControl};
if (alive _unit && {!isPlayer _unit}) then {
    _unit suppressFor 0;
    _unit doWatch objNull;
    private _group = group _unit;
    if (_unit != leader _group) then {_unit doFollow leader _group} else {
        // Finish a leader's temporary doMove immediately, then let its waypoints resume.
        _unit doMove getPosATL _unit;
    };
};
_unit setVariable ["VCM_BoundKey", nil, true];
if (_unit getVariable ["VCM_DebugBoundRole",[]] isNotEqualTo []) then {_unit setVariable ["VCM_DebugBoundRole",nil,true]};
