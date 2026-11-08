/* Synchronous projectile guard covers the interval between safety ticks. It does not affect players. */
params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];
if (!local _unit || {[_unit] call VCM_fnc_HumanControlled} || {isNull _projectile} ||
    {!([group _unit] call VCM_fnc_GroupEnabled)}) exitWith {true};
if (_weapon == "Throw" && {VCM_NOGRENADESINDOORS} && {[_unit,true] call VCM_fnc_InsideBarracks}) exitWith {
    deleteVehicle _projectile;
    _unit setVariable ["VCM_BlockedThrows", 1 + (_unit getVariable ["VCM_BlockedThrows", 0])];
    private _stored = +(_unit getVariable ["VCM_StoredGrenades", []]);
    _stored pushBack [_magazine, 1];
    _unit setVariable ["VCM_StoredGrenades", _stored, true];
    false
};
private _smokeAim = _unit getVariable ["VCM_SmokeAim",[]];
if (_weapon == "Throw" && {_smokeAim isNotEqualTo []} && {_smokeAim select 0 == _magazine} && {time < (_smokeAim select 2)}) then {
    _projectile setVelocity (_smokeAim select 1);
    _unit setVariable ["VCM_LastSmoke",[time,_projectile],true];
};
if (_weapon == "Throw" && {VCM_GRENADESAFETY}) then {
    private _prediction = [_unit,_ammo,getPosASL _projectile,velocity _projectile,_projectile] call VCM_fnc_ThrowSafe;
    if (!(_prediction select 0)) then {
        deleteVehicle _projectile;
        private _stored = +(_unit getVariable ["VCM_StoredGrenades",[]]);
        _stored pushBack [_magazine,1];
        _unit setVariable ["VCM_StoredGrenades",_stored,true];
        _unit setVariable ["VCM_ThrowBlockUntil",time + 5,true];
        [group _unit,"throw-veto",_prediction select 2] call VCM_fnc_DebugTrace;
    };
};
if (isNull _projectile) exitWith {false};
if (VCM_ATCOORD && {_weapon == secondaryWeapon _unit} && {_weapon != ""}) then {
    private _target = getAttackTarget _unit;
    if (isNull _target) then {_target = assignedTarget _unit};
    private _lease = _target getVariable ["VCM_ATLease",[]];
    if (_lease isNotEqualTo [] && {time < (_lease select 1)}) then {
        private _shots = _target getVariable ["VCM_ATFired",[[],0]];
        private _point = [_unit,_target] call VCM_fnc_ContactPosition;
        if (!(unitCombatMode _unit in ["YELLOW","RED"]) || {_unit != (_lease select 0)} ||
            {(_shots select 0) isEqualTo (_lease select 2) && {_shots select 1 > 0}} ||
            {_point isEqualTo []} || {!([_unit,_target,_point] call VCM_fnc_ATLaneClear)}) then {
            deleteVehicle _projectile;
            [_unit,[[_magazine,1]]] call VCM_fnc_ReturnMagazines;
            [group _unit,"at-veto","reservation or unsafe firing lane"] call VCM_fnc_DebugTrace;
        } else {
            _target setVariable ["VCM_ATFired",[_lease select 2,1],true];
            [group _unit,"at-fired",netId _target] call VCM_fnc_DebugTrace;
        };
    };
};
if (isNull _projectile) exitWith {false};
private _vehicle = vehicle _unit;
private _indirect = _vehicle != _unit && {getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "artilleryScanner") == 1};
if (VCM_WALLCHECK && {!_indirect} && {toLower getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotbullet","shotshell"]}) then {
    private _target = getAttackTarget _unit;
    if (isNull _target) then {_target = assignedTarget _unit};
    private _position = [_unit, _target] call VCM_fnc_ContactPosition;
    if (_position isNotEqualTo []) then {
        private _start = getPosASL _projectile;
        private _end = _start vectorAdd ((vectorNormalized velocity _projectile) vectorMultiply (_unit distance2D _position));
        if (!([_start, _end, _vehicle, _target] call VCM_fnc_PhysicalFireLane)) then {deleteVehicle _projectile};
    };
};
!isNull _projectile
