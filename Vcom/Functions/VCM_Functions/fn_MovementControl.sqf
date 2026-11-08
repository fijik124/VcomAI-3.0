/* A moving team follows its explicit route instead of autonomous ATTACK orders. Restore every owned feature. */
params ["_unit",["_key",[]]];
if (!local _unit) exitWith {};
private _saved = _unit getVariable ["VCM_MovementControl",[]];
if (_saved isNotEqualTo [] && {_key isNotEqualTo []} && {(_saved select 0) isEqualTo _key}) exitWith {};
if (_saved isNotEqualTo []) then {
    _unit setVariable ["VCM_MovementControl",nil,true];
    if (count _saved > 2 && {(waypoints group _unit) findIf {(_x select 1) > 0} < 0}) then {_unit setCombatBehaviour (_saved select 2)};
    {if (_x select 1) then {_unit enableAI (_x select 0)}} forEach (_saved select 1);
};
if (_key isNotEqualTo []) then {
    private _features = ["TARGET","AUTOTARGET","AUTOCOMBAT","FSM"] apply {[_x,_unit checkAIFeature _x]};
    _unit setVariable ["VCM_MovementControl",[_key,_features,behaviour _unit],true];
    {if (_x select 1) then {_unit disableAI (_x select 0)}} forEach _features;
    _unit doTarget objNull;
    _unit doFire objNull;
    _unit doFollow leader group _unit;
    _unit setCombatBehaviour "AWARE";
};
