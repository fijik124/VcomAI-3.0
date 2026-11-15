/* Restore only the engagement restriction owned by reconnaissance. Never overwrite a newer mission order. */
params ["_unit"];
if (!local _unit) exitWith {};
private _saved = _unit getVariable ["VCM_ReconROE",[]];
if (_saved isNotEqualTo []) then {
    if (unitCombatMode _unit == "GREEN") then {_unit setUnitCombatMode (_saved select 0)};
    _unit setVariable ["VCM_ReconROE",nil,true];
};
