/* Local infantry safety. Never loosen engagement rules or enable a mission-disabled firing feature. */
params ["_unit", "_run",["_force",false]];
if (!local _unit) exitWith {};
if ([_unit] call VCM_fnc_HumanControlled) exitWith {[_unit] call VCM_fnc_MovementControl; [_unit] call VCM_fnc_RestoreSafety};
private _handlerRun = (_unit getVariable ["VCM_Handlers",[[],[]]]) select 0;
if (_handlerRun isNotEqualTo [] && {!(_handlerRun isEqualTo _run)}) exitWith {};
if (!_force && {diag_tickTime < (_unit getVariable ["VCM_NextSafety",-1])}) exitWith {};
_unit setVariable ["VCM_NextSafety",diag_tickTime + 0.5];
private _vehicle = vehicle _unit;
if (_vehicle != _unit && {_unit == driver _vehicle}) then {
    private _partner = _vehicle getVariable ["VCM_InfantryPartner",[]];
    if (_partner isNotEqualTo [] && {time > (_partner param [2,-1]) ||
        {(_partner param [3,""]) != "remote" && {groupOwner (_partner select 0) != clientOwner}}}) then {
        _vehicle setVariable ["VCM_InfantryPartner",nil,true];
        if (!isPlayer _unit && {(waypoints group _unit) findIf {(_x select 1) > 0} < 0}) then {doStop _unit};
    };
};
private _directGunner = _vehicle != _unit && {_unit == gunner _vehicle} &&
    {getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "artilleryScanner") != 1};
if (!([_unit, group _unit, _run] call VCM_fnc_ActionValid) || {_vehicle != _unit && {!_directGunner}}) exitWith {
    private _movement = _unit getVariable ["VCM_MovementControl",[]];
    if (_movement isNotEqualTo [] && {(_movement select 0 select 0) isEqualTo _run}) then {[_unit] call VCM_fnc_MovementControl};
    [_unit] call VCM_fnc_RestoreSafety;
};
private _target = getAttackTarget _unit;
if (isNull _target) then {_target = assignedTarget _unit};
private _blocked = false;
if (VCM_WALLCHECK && {!isNull _target} && {alive _target}) then {
    private _position = [_unit, _target] call VCM_fnc_ContactPosition;
    if (_position isNotEqualTo []) then {
        _blocked = !([eyePos _unit, ATLToASL (_position vectorAdd [0,0,1]), _vehicle, _target] call VCM_fnc_PhysicalFireLane);
    };
};
if (VCM_ATCOORD && {!isNull _target} && {_target isKindOf "LandVehicle"} &&
    {secondaryWeapon _unit != ""} && {currentWeapon _unit == secondaryWeapon _unit}) then {
    private _lease = _target getVariable ["VCM_ATLease",[]];
    if (_lease isNotEqualTo [] && {time < (_lease select 1)}) then {
        private _point = [_unit,_target] call VCM_fnc_ContactPosition;
        private _shots = _target getVariable ["VCM_ATFired",[[],0]];
        _blocked = _blocked || {!(unitCombatMode _unit in ["YELLOW","RED"])} || {_unit != (_lease select 0)} ||
            {(_shots select 0) isEqualTo (_lease select 2) && {_shots select 1 > 0}} ||
            {_point isEqualTo []} || {!([_unit,_target,_point] call VCM_fnc_ATLaneClear)};
    };
};
if (_blocked) then {
    if (_unit checkAIFeature "FIREWEAPON" && {_unit getVariable ["VCM_FireLock", []] isEqualTo []}) then {
        _unit setVariable ["VCM_FireLock", [_run, true], true];
        _unit disableAI "FIREWEAPON";
    };
} else {[_unit, true] call VCM_fnc_RestoreSafety};
private _stored = +(_unit getVariable ["VCM_StoredGrenades",[]]);
private _hasThrows = (magazines _unit) findIf {VCM_ThrowMagazineSet getOrDefault [_x,false]} >= 0;
private _inside = _vehicle == _unit && {VCM_NOGRENADESINDOORS} && {_hasThrows || {_stored isNotEqualTo []}} && {[_unit] call VCM_fnc_InsideBarracks};
private _blastUnsafe = false;
if (_vehicle == _unit && {VCM_GRENADESAFETY} && {!isNull _target}) then {
    private _point = [_unit,_target] call VCM_fnc_ContactPosition;
    if (_point isNotEqualTo [] && {_unit distance2D _point < 70}) then {
        _blastUnsafe = !([side group _unit,_point,VCM_GRENADEFRIENDLY] call VCM_fnc_ArtillerySafe);
    };
};
private _cooldown = VCM_GRENADESAFETY && {time < (_unit getVariable ["VCM_ThrowBlockUntil",-1])};
private _keep = {
    params ["_magazine"];
    private _info = VCM_ThrowInfo getOrDefault [_magazine,[]];
    _info isNotEqualTo [] && {_inside || {_cooldown} || {_blastUnsafe && {_info select 1}}}
};
private _restore = _stored select {!([_x select 0] call _keep)};
_stored = _stored - _restore;
// Preserve an active firing lock while restoring only the stored inventory.
if (_restore isNotEqualTo []) then {[_unit,_restore] call VCM_fnc_ReturnMagazines};
private _classes = [];
if (_vehicle == _unit && {_inside || {_blastUnsafe} || {_cooldown}}) then {
    {
        _x params ["_magazine","_rounds"];
        if ([_magazine] call _keep) then {_stored pushBack [_magazine,_rounds]; _classes pushBackUnique _magazine};
    } forEach magazinesAmmoFull _unit;
    {_unit removeMagazines _x} forEach _classes;
};
if (_stored isNotEqualTo (_unit getVariable ["VCM_StoredGrenades",[]])) then {
    _unit setVariable ["VCM_StoredGrenades",_stored,true];
};
