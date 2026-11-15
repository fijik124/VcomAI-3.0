/* Group cleanup restores owned formation preferences; per-unit policies have independent ownership records. */
params ["_group"];
if (!local _group) exitWith {};
private _saved = _group getVariable ["VCM_DoctrineFormation",[]];
if (_saved isNotEqualTo []) then {
    if (formation _group == _saved select 1) then {_group setFormation (_saved select 0)};
    _group setVariable ["VCM_DoctrineFormation",nil,true];
};
[_group] call VCM_fnc_NightRelease;
{[_x] call VCM_fnc_ReconRelease} forEach units _group;
_group setVariable ["VCM_ReconPolicyActive",false,true];
