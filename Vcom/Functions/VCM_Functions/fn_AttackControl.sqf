/* Prevent the leader from replacing a committed move with native ATTACK orders; retain unit targeting and ROE. */
params ["_group",["_key",[]]];
if (!local _group) exitWith {};
private _saved = _group getVariable ["VCM_AttackControl",[]];
if (_saved isNotEqualTo [] && {_key isNotEqualTo []} && {(_saved select 0) isEqualTo _key}) exitWith {};
if (_saved isNotEqualTo []) then {
    if (_saved select 1) then {_group enableAttack true};
    _group setVariable ["VCM_AttackControl",nil,true];
};
if (_key isNotEqualTo []) then {
    private _enabled = attackEnabled _group;
    _group setVariable ["VCM_AttackControl",[_key,_enabled],true];
    if (_enabled) then {_group enableAttack false};
};
