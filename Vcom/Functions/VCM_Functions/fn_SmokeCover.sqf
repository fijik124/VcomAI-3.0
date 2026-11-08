/* Scheduled native throw from carried supplies. The FiredMan guard applies the planned ballistic velocity. */
params ["_unit","_threat",["_key",[]]];
private _group = group _unit;
private _run = _group getVariable ["VCM_RunId",[]];
if (!VCM_SMOKECOVER || {!([_unit,_group,_run] call VCM_fnc_ActionValid)} ||
    {!isNull objectParent _unit} || {[_unit,true] call VCM_fnc_InsideBarracks} ||
    {diag_tickTime < (_group getVariable ["VCM_SmokeAfter",-1])}) exitWith {false};
private _magazine = (magazines _unit) select {
    private _data = VCM_ThrowInfo getOrDefault [_x,[]];
    _data isNotEqualTo [] && {_data select 2}
};
if (_magazine isEqualTo []) exitWith {[_group,"smoke-skipped","no carried smoke"] call VCM_fnc_DebugTrace; false};
_magazine = _magazine select 0;
private _point = _unit getPos [15,_unit getDir _threat];
private _start = eyePos _unit;
private _flight = 1.5;
private _velocity = ((ATLToASL _point) vectorDiff _start) vectorMultiply (1 / _flight);
_velocity set [2,(_velocity select 2) + 4.905 * _flight];
private _ammo = (VCM_ThrowInfo get _magazine) select 0;
private _prediction = [_unit,_ammo,_start,_velocity] call VCM_fnc_ThrowSafe;
if (!(_prediction select 0)) exitWith {[_group,"smoke-skipped",_prediction select 2] call VCM_fnc_DebugTrace; false};
_group setVariable ["VCM_SmokeAfter",diag_tickTime + VCM_SMOKECOOLDOWN];
private _weapon = currentWeapon _unit;
_unit doWatch _threat;
_unit selectThrowable _magazine;
private _deadline = diag_tickTime + 6;
waitUntil {
    sleep 0.1;
    !([_unit,_group,_run] call VCM_fnc_ActionValid) || {diag_tickTime >= _deadline} ||
    {private _state = _unit weaponState ((currentThrowable _unit) param [1,""]); count _state > 6 && {_state select 6 == 0}}
};
private _validKey = _key isEqualTo [] || {(_unit getVariable ["VCM_TaskKey",[]]) isEqualTo _key} ||
    {(_unit getVariable ["VCM_BoundKey",[]]) isEqualTo _key};
if (!([_unit,_group,_run] call VCM_fnc_ActionValid) || {!_validKey} || {[_unit,true] call VCM_fnc_InsideBarracks}) exitWith {false};
private _muzzle = (currentThrowable _unit) param [1,""];
if (_muzzle == "" || {!(_magazine in magazines _unit)}) exitWith {[_group,"smoke-skipped",format ["no ready muzzle %1",currentThrowable _unit]] call VCM_fnc_DebugTrace; false};
_unit setVariable ["VCM_SmokeAim",[_magazine,_velocity,time + 3]];
[_group,"smoke-order",format ["%1 muzzle=%2 state=%3",currentThrowable _unit,_muzzle,_unit weaponState _muzzle]] call VCM_fnc_DebugTrace;
_unit forceWeaponFire [_muzzle,_muzzle];
private _throwDeadline = diag_tickTime + 3;
waitUntil {sleep 0.1;
    private _last = _unit getVariable ["VCM_LastSmoke",[]];
    _last isNotEqualTo [] && {time - (_last select 0) < 3} ||
    {diag_tickTime >= _throwDeadline} || {!([_unit,_group,_run] call VCM_fnc_ActionValid)}
};
private _thrown = _unit getVariable ["VCM_LastSmoke",[]];
_unit setVariable ["VCM_SmokeAim",nil];
if ([_unit,_group,_run] call VCM_fnc_ActionValid && {_validKey}) then {
    if (_weapon != "" && {_weapon != "Throw"}) then {_unit selectWeapon _weapon};
};
[_group,"smoke",format ["%1 %2",_unit,_thrown]] call VCM_fnc_DebugTrace;
_thrown isNotEqualTo [] && {time - (_thrown select 0) < 3}
