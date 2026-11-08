/* Existing mission routes stay in place; speed ownership and detours are finite and reversible. */
params ["_group"];
private _vehicles = [];
{if (vehicle _x isKindOf "LandVehicle") then {_vehicles pushBackUnique vehicle _x}} forEach units _group;
private _ready = VCM_CONVOY && {!(_group getVariable ["VCM_NOAUTOTACTICS",false])} &&
    {!(_group getVariable ["VCM_NOFLANK",false])} && {_group getVariable ["VCM_ArmorPartner",[]] isEqualTo []} &&
    {_group getVariable ["VCM_Task",[]] isEqualTo []};
private _eligible = _vehicles select {
    local _x && {alive _x} && {canMove _x} && {fuel _x > 0} && {!(_x isKindOf "StaticWeapon")} &&
    {alive driver _x} && {local driver _x} && {group driver _x == _group} &&
    {(crew _x) findIf {[_x] call VCM_fnc_HumanControlled} < 0}
};
if (!_ready || {count _eligible < 2}) exitWith {{[_x] call VCM_fnc_ConvoyRelease} forEach _vehicles};
private _run = _group getVariable ["VCM_RunId",[]];
{
    private _vehicle = _x;
    private _record = _vehicle getVariable ["VCM_ConvoyControl",[]];
    if (_record isNotEqualTo [] && {!((_record select 0) isEqualTo _run)}) then {[_vehicle] call VCM_fnc_ConvoyRelease; _record = []};
    if (_record isEqualTo []) then {
        _record = [_run,getForcedSpeed _vehicle,getForcedSpeed _vehicle,getPosATL _vehicle,diag_tickTime,0];
        _vehicle setVariable ["VCM_ConvoyControl",_record,true];
    };
    // A mission changing forceSpeed during a convoy becomes the new limit to preserve on release.
    if (abs (getForcedSpeed _vehicle - (_record select 2)) > 0.01) then {_record set [1,getForcedSpeed _vehicle]};
    private _limit = VCM_CONVOYSPEED / 3.6;
    if (_record select 1 >= 0) then {_limit = _limit min (_record select 1)};
    private _ahead = 1e6;
    {
        private _offset = (getPosATL _x) vectorDiff getPosATL _vehicle;
        private _along = _offset vectorDotProduct vectorDir _vehicle;
        if (_x != _vehicle && {_along > 0} && {_along < _ahead} &&
            {vectorMagnitude (_offset vectorDiff ((vectorDir _vehicle) vectorMultiply _along)) < 10}) then {_ahead = _along};
    } forEach _eligible;
    if (_ahead < VCM_CONVOYGAP) then {_limit = _limit min (if (_ahead < VCM_CONVOYGAP * 0.6) then {0} else {3})};
    if (_vehicle == vehicle leader _group && {_eligible findIf {_x distance2D _vehicle > VCM_CONVOYGAP * 3} >= 0}) then {_limit = _limit min (VCM_CONVOYSPEED / 7.2)};
    private _clear = [_vehicle,8 + (abs speed _vehicle / 3.6 * 2) min 25] call VCM_fnc_VehicleFrontClear;
    if (!_clear) then {_limit = 0};
    if (abs (getForcedSpeed _vehicle - _limit) > 0.01) then {_vehicle forceSpeed _limit};
    private _changed = abs ((_record select 2) - _limit) > 0.01;
    _record set [2,_limit];
    if (_changed) then {_vehicle setVariable ["VCM_ConvoyControl",_record,true]};
    if (diag_tickTime - (_record select 4) >= VCM_UNSTUCKSECONDS) then {
        if (VCM_UNSTUCK && {_clear} && {_limit > 0} && {_vehicle distance (_record select 3) < 1} &&
            {(_record select 5) < floor VCM_UNSTUCKTRIES} && {currentWaypoint _group > 0}) then {
            private _goal = waypointPosition [_group,currentWaypoint _group];
            if (_vehicle distance2D _goal > 10) then {
                private _side = [-1,1] select ((_record select 5) mod 2 == 0);
                private _detour = (_vehicle getPos [VCM_UNSTUCKRADIUS + 3,getDir _vehicle + 60 * _side]) findEmptyPosition [0,4,typeOf _vehicle];
                if (_detour isNotEqualTo [] && {!surfaceIsWater _detour}) then {
                    _vehicle setVariable ["VCM_ConvoyRecovery",[_detour,_goal,diag_tickTime + 15,currentWaypoint _group]];
                    driver _vehicle doMove _detour;
                    [ _group,"convoy-recovery",format ["%1 %2",_vehicle,_detour]] call VCM_fnc_DebugTrace;
                };
                _record set [5,1 + (_record select 5)];
            };
        };
        _record set [3,getPosATL _vehicle]; _record set [4,diag_tickTime];
    };
    private _recovery = _vehicle getVariable ["VCM_ConvoyRecovery",[]];
    if (_recovery isNotEqualTo [] && {_vehicle distance2D (_recovery select 0) < 4 ||
        {diag_tickTime > (_recovery select 2)} || {currentWaypoint _group != _recovery select 3}}) then {
        if (currentWaypoint _group == _recovery select 3) then {driver _vehicle doMove (_recovery select 1)};
        _vehicle setVariable ["VCM_ConvoyRecovery",nil];
    };
    if (VCM_Debug) then {_vehicle setVariable ["VCM_DebugConvoy",[_limit,_ahead,_clear],true]};
} forEach _eligible;
{if (!(_x in _eligible)) then {[_x] call VCM_fnc_ConvoyRelease}} forEach _vehicles;
