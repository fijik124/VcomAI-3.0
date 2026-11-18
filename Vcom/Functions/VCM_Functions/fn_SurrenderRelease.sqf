/* Dropped equipment stays on the ground. ACE retains ownership of restraints and escorting. */
params ["_unit"];
if (!local _unit) exitWith {};
private _state = _unit getVariable ["VCM_SurrenderState",[]];
if (_state isEqualTo []) exitWith {};
_state params ["_group","_features","_stance","_speed","_behaviour","_captive","_ace"];
_unit setVariable ["VCM_SurrenderState",nil,true];
private _handcuffed = _unit getVariable ["ace_captives_isHandcuffed",false];
if (_ace) then {
    if (!_handcuffed && {_unit getVariable ["ace_captives_isSurrendering",false]}) then {[_unit,false] call ace_captives_fnc_setSurrendered};
} else {
    if (!_handcuffed && {!(_unit getVariable ["ace_captives_isSurrendering",false])}) then {_unit setCaptive _captive};
};
{if (_x select 1) then {_unit enableAI (_x select 0)} else {_unit disableAI (_x select 0)}} forEach _features;
_unit setUnitPos _stance;
_unit forceSpeed _speed;
if (alive _unit && {lifeState _unit != "INCAPACITATED"} && {!(_unit getVariable ["ACE_isUnconscious",false])}) then {
    _unit setCombatBehaviour _behaviour;
    if (!_ace && {!_handcuffed} && {toLower animationState _unit find "amovpercmstpssur" == 0}) then {
        _unit switchMove "AmovPercMstpSnonWnonDnon";
    };
    if (!_handcuffed && {!([_unit] call VCM_fnc_HumanControlled)} && {isNull objectParent _unit}) then {
        _unit doMove getPosATL _unit;
        if (_unit != leader group _unit) then {_unit doFollow leader group _unit};
    };
};
if (local _group) then {
    _group setVariable ["VCM_SurrenderAfter",time + 60,true];
    if ((units _group) findIf {_x getVariable ["VCM_SurrenderState",[]] isNotEqualTo []} < 0) then {
        _group setVariable ["VCM_Surrendered",false,true];
    };
};
