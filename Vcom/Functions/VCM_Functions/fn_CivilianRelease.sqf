/* Public snapshots survive a headless-client handoff. Restore only the features this reaction owned. */
params ["_unit"];
if (!local _unit) exitWith {};
private _state = _unit getVariable ["VCM_CivilianState",[]];
if (_state isEqualTo []) exitWith {};
_state params ["_group","_features","_stance","_speed","_behaviour"];
_unit setVariable ["VCM_CivilianState",nil,true];
_unit setVariable ["VCM_CivilianThreat",nil,true];
{if (_x select 1) then {_unit enableAI (_x select 0)} else {_unit disableAI (_x select 0)}} forEach _features;
_unit setUnitPos _stance;
_unit forceSpeed _speed;
if (alive _unit && {lifeState _unit != "INCAPACITATED"} && {!(_unit getVariable ["ACE_isUnconscious",false])}) then {
    _unit setCombatBehaviour _behaviour;
    if (!([_unit] call VCM_fnc_HumanControlled) && {isNull objectParent _unit}) then {
        _unit doMove getPosATL _unit;
        if (_unit != leader group _unit) then {_unit doFollow leader group _unit};
    };
};
