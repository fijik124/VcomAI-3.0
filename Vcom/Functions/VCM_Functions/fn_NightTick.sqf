/* Optional attachment discipline; equipment is never added, replaced or replenished. */
params ["_group"];
private _mode = _group getVariable ["VCM_NightMode","auto"];
private _active = VCM_NIGHTDISCIPLINE && {sunOrMoon < 0.2} &&
    {[_group] call VCM_fnc_GroupEnabled} && {!(_group getVariable ["VCM_NONIGHT",false])} &&
    {(units _group) findIf {[_x] call VCM_fnc_HumanControlled} < 0};
if (!_active) exitWith {[_group] call VCM_fnc_NightRelease};
if (!(_group getVariable ["VCM_NightOwned",false])) then {_group setVariable ["VCM_NightOwned",true,true]};
private _canManageIR = (units _group) findIf {!(_x checkAIFeature "LIGHTS") &&
    {_x getVariable ["VCM_NightState",[]] isEqualTo []}} < 0;
if (_canManageIR && {_group getVariable ["VCM_NightIRControl",[]] isEqualTo []}) then {
    private _wasOn = (units _group) findIf {_x isIRLaserOn primaryWeapon _x} >= 0;
    _group setVariable ["VCM_NightIRControl",[_wasOn],true];
};
private _useIR = false;
private _observation = if (VCM_COMMANDPOINTS && {VCM_RECON}) then {_group getVariable ["VCM_Objective",[]]} else {[]};
private _stealth = ([_group] call VCM_fnc_Doctrine) == "recon" || {_mode == "blackout"} ||
    {_observation isNotEqualTo [] && {_observation select 1 == "recon"}};
private _enemy = objNull;
private _contact = [];
if (_active && {!_stealth}) then {
    _enemy = leader _group call VCM_fnc_ClstEmy;
    _contact = [leader _group,_enemy] call VCM_fnc_ContactPosition;
};
{
    private _unit = _x;
    if (_active && {local _unit} && {alive _unit} && {!([_unit] call VCM_fnc_HumanControlled)} &&
        {isNull objectParent _unit} && {primaryWeapon _unit != ""} &&
        {_unit checkAIFeature "LIGHTS" || {_unit getVariable ["VCM_NightState",[]] isNotEqualTo []}}) then {
        private _weapon = primaryWeapon _unit;
        private _saved = +(_unit getVariable ["VCM_NightState",[]]);
        if (_saved isNotEqualTo [] && {_saved select 1 != _weapon}) then {[_unit] call VCM_fnc_RestoreNight; _saved = []};
        if (_saved isEqualTo []) then {
            _saved = [_unit checkAIFeature "LIGHTS",_weapon,_unit isFlashlightOn _weapon,_unit isIRLaserOn _weapon,false,false];
            _unit disableAI "LIGHTS";
        };
        private _nvg = (assignedItems _unit) findIf {
            getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "type") == 616
        } >= 0;
        private _flash = !_stealth && {!_nvg} && {VCM_NIGHTFLASHLIGHTS || {_mode == "illuminate"}} &&
            {_contact isNotEqualTo []} && {_unit distance2D _contact <= 150};
        private _laser = !_stealth && {_nvg} && {_contact isNotEqualTo []} && {unitCombatMode _unit in ["YELLOW","RED"]};
        if (_laser) then {_useIR = true};
        _unit action [["GunLightOff","GunLightOn"] select _flash,_unit];
        _unit action [["IRLaserOff","IRLaserOn"] select _laser,_unit];
        _saved set [4,_unit isFlashlightOn _weapon]; _saved set [5,_laser];
        if (_saved isNotEqualTo (_unit getVariable ["VCM_NightState",[]])) then {_unit setVariable ["VCM_NightState",_saved,true]};
    } else {[_unit] call VCM_fnc_RestoreNight};
} forEach units _group;
if (_canManageIR) then {
    _group enableIRLasers _useIR;
    {
        private _state = _x getVariable ["VCM_NightState",[]];
        if (_state isNotEqualTo [] && {!(_state select 5)}) then {_x action ["IRLaserOff",_x]};
    } forEach units _group;
};
if (_active && {!_stealth} && {VCM_NIGHTFLARES || {_mode == "illuminate"}} && {_contact isNotEqualTo []} &&
    {leader _group distance2D _contact <= 150} &&
    {(units _group) findIf {(assignedItems _x) findIf {getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "type") == 616} >= 0} < 0} &&
    {_group getVariable ["VCM_Task",[]] isEqualTo []} && {_group getVariable ["VCM_BoundState",[]] isEqualTo []}) then {
    private _thrower = ([_group] call VCM_fnc_TacticalUnits) param [0,objNull];
    if (!isNull _thrower) then {[_thrower,_contact,[],"flare"] spawn VCM_fnc_SmokeCover};
};
