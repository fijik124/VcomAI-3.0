/* Maintain inherited surrender without repeating its inventory transfer or overriding ACE captivity. */
params ["_unit"];
if (!local _unit) exitWith {};
private _state = _unit getVariable ["VCM_SurrenderState",[]];
if (_state isEqualTo []) exitWith {};
private _group = group _unit;
if (!Vcm_ActivateAI || {!VCM_SURRENDER} || {!alive _unit} || {[_unit] call VCM_fnc_HumanControlled} ||
    {!isNull objectParent _unit} || {lifeState _unit == "INCAPACITATED"} || {_unit getVariable ["ACE_isUnconscious",false]} ||
    {_unit getVariable ["ace_captives_isHandcuffed",false]} || {_group != _state select 0} ||
    {!(_group getVariable ["VCM_Surrendered",false])} || {_group getVariable ["Vcm_Disable",false]} ||
    {_group getVariable ["VCM_NOSURRENDER",false]} || {_unit getVariable ["VCM_NOSURRENDER",false]} ||
    {!((side _group) in VCM_SIDEENABLED)} ||
    {_state select 6 && {!(_unit getVariable ["ace_captives_isSurrendering",false])}}) exitWith {[_unit] call VCM_fnc_SurrenderRelease};
// Local AI features, stance and forceSpeed reset on handoff even though the public snapshot survives.
if ((_state param [7,-1]) != clientOwner) then {
    {_unit disableAI (_x select 0)} forEach (_state select 1);
    _unit setUnitPos "UP";
    _unit forceSpeed 0;
    _unit doTarget objNull;
    _unit doWatch objNull;
    doStop _unit;
    _state set [7,clientOwner];
    _unit setVariable ["VCM_SurrenderState",_state,true];
};
// A completed inventory transfer is public state; never repeat it from a stale handoff inventory.
if (VCM_SURRENDERDROP && {!(_state param [8,false])}) then {
    private _holder = [_unit] call VCM_fnc_DropWeapons;
    _state set [8,!isNull _holder || {[primaryWeapon _unit,handgunWeapon _unit,secondaryWeapon _unit] isEqualTo ["","",""]}];
    _unit setVariable ["VCM_SurrenderState",_state,true];
};
if (!(_state select 6) && {!captive _unit}) exitWith {[_unit] call VCM_fnc_SurrenderRelease};
if (!(_state select 6) && {toLower animationState _unit find "amovpercmstpssur" != 0}) then {
    _unit switchMove "AmovPercMstpSsurWnonDnon";
};
