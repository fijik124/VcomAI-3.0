if (!(isServer && {!isRemoteExecuted}) && {!isRemoteExecuted || {remoteExecutedOwner != 2}}) exitWith {};
params ["_group","_role","_goal","_enemy","_contact","_key","_expiry"];
if (!local _group || {!VCM_MULTISQUAD} || {!([_group] call VCM_fnc_TacticalReady)} || {time >= _expiry}) exitWith {};
if (!(_group in VcmAI_ActiveList)) then {_group call VCM_fnc_SquadExc};
private _deadline = diag_tickTime + 3;
waitUntil {sleep 0.1; count ([_group] call VCM_fnc_TacticalUnits) >= 4 || {diag_tickTime > _deadline} || {!local _group}};
private _units = ([_group] call VCM_fnc_TacticalUnits) select [0,8];
if (count _units < 4) exitWith {[_group,_key] call VCM_fnc_CoordRelease};
_group setVariable ["VCM_LastSquadRole",[_role,_key,clientOwner,_goal],true];
[_group,"squad-role",_role] call VCM_fnc_DebugTrace;
if (_role == "support") then {
    [_group,"cooperate",[[_units,[],[],10,_contact]],_enemy,_contact] call VCM_fnc_RunTactical;
} else {
    private _support = _units select [0,2];
    private _movers = _units - _support;
    private _positions = [];
    {
        private _point = (_x getPos [(_x distance2D _goal) min 30,_x getDir _goal]) findEmptyPosition [0,3,typeOf _x];
        if (_point isNotEqualTo [] && {_positions findIf {_x distance2D _point < 3} < 0}) then {_positions pushBack _point};
    } forEach _movers;
    if (count _positions == count _movers) then {
        [_group,"cooperate",[[_support,_movers,_positions,25,_contact]],_enemy,_contact] call VCM_fnc_RunTactical;
    };
};
[_group,_key] call VCM_fnc_CoordRelease;
