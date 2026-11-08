if (!(isServer && {!isRemoteExecuted}) && {!isRemoteExecuted || {remoteExecutedOwner != 2}}) exitWith {};
params ["_group","_shooter","_enemy","_point","_leaseKey","_expiry"];
if (!local _group || {!local _shooter} || {!VCM_ATCOORD} || {!([_group] call VCM_fnc_TacticalReady)} ||
    {!alive _enemy} || {secondaryWeapon _shooter == ""} || {!(unitCombatMode _shooter in ["YELLOW","RED"])}) exitWith {};
if (!(_group in VcmAI_ActiveList)) then {_group call VCM_fnc_SquadExc};
private _deadline = diag_tickTime + 3;
waitUntil {sleep 0.1; _shooter in ([_group] call VCM_fnc_TacticalUnits) || {diag_tickTime > _deadline} || {!local _group}};
private _units = ([_group] call VCM_fnc_TacticalUnits) select [0,8];
if (!(_shooter in _units)) exitWith {[_group,_leaseKey] call VCM_fnc_CoordRelease};
private _weapon = currentWeapon _shooter;
_shooter setVariable ["VCM_ATWeapon",[_leaseKey,_weapon],true];
_group setVariable ["VCM_ATShooter",_shooter];
private _job = [_group,"antitank",[[_units,[],[],(_expiry - time) min 15,_point]],_enemy,_point] spawn VCM_fnc_RunTactical;
sleep 0.1;
private _key = (_group getVariable ["VCM_Task",[]]) param [0,[]];
private _fired = false;
while {!scriptDone _job && {time < _expiry} && {local _shooter} && {alive _enemy} &&
    {unitCombatMode _shooter in ["YELLOW","RED"]} && {!([_shooter] call VCM_fnc_HumanControlled)}} do {
    if ([_shooter,_enemy,_point] call VCM_fnc_ATLaneClear) then {
        _shooter selectWeapon secondaryWeapon _shooter;
        _shooter doTarget _enemy;
        _shooter doFire _enemy;
    };
    if ((_enemy getVariable ["VCM_ATFired",[[],0]]) select 1 > 0) exitWith {_fired = true};
    sleep 0.25;
};
if (_fired) then {sleep 2};
if (_key isNotEqualTo []) then {[_group,_key,if (_fired) then {"rocket-fired"} else {"at-timeout"}] call VCM_fnc_EndTactical};
if (local _shooter && {((_shooter getVariable ["VCM_ATWeapon",[]]) param [0,[]]) isEqualTo _leaseKey}) then {
    if (!([_shooter] call VCM_fnc_HumanControlled) && {_weapon != ""}) then {_shooter selectWeapon _weapon};
    _shooter setVariable ["VCM_ATWeapon",nil,true];
};
if (local _group) then {_group setVariable ["VCM_ATShooter",nil]; _group setVariable ["VCM_LastAT",[_fired,_enemy,clientOwner],true]};
[_group,_leaseKey] call VCM_fnc_CoordRelease;
