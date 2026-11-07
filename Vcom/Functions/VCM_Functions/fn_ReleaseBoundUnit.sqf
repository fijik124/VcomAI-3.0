params ["_unit", "_key"];
if (!local _unit || {!(_key isEqualTo (_unit getVariable ["VCM_BoundKey", []]))}) exitWith {};
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
