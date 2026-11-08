/* Fixed-data coordination. Server selects recipients and leases; clients never send CODE or owner IDs. */
if (!isServer || {!Vcm_ActivateAI}) exitWith {false};
params [["_caller",grpNull,[grpNull]],["_kind","",[""]],["_enemy",objNull,[objNull]],
    ["_point",[],[[]]],["_asset",objNull,[objNull]],["_identity",objNull,[objNull]]];
if (!(_kind in ["squads","escort","at"]) || {!([_caller] call VCM_fnc_CoordReady)} ||
    {isNull _enemy} || {!alive _enemy} || {!([side _caller,side _enemy] call BIS_fnc_sideIsEnemy)} ||
    {count _point != 3} || {_point findIf {!(_x isEqualType 0) || {!finite _x}} >= 0} ||
    {leader _caller distance2D _point > 2000} || {_caller getVariable ["VCM_TOUGHSQUAD",false]}) exitWith {false};
private _owner = groupOwner _caller;
private _sender = remoteExecutedOwner;
if (_sender > 0 && {_sender != _owner}) exitWith {false};
if (_sender == 0 && {_owner != 2} && {isNull _identity || {!(_identity isKindOf "HeadlessClient_F")} || {owner _identity != _owner}}) exitWith {false};
if (isNil "VCM_CoordTimes") then {VCM_CoordTimes = createHashMap};
if (diag_tickTime > (missionNamespace getVariable ["VCM_CoordSweep",-1])) then {
    {if (VCM_CoordTimes get _x < diag_tickTime) then {VCM_CoordTimes deleteAt _x}} forEach keys VCM_CoordTimes;
    VCM_CoordSweep = diag_tickTime + 60;
};
private _rate = format ["%1:%2",netId _caller,_kind];
if (diag_tickTime < (VCM_CoordTimes getOrDefault [_rate,-1])) exitWith {false};
VCM_CoordTimes set [_rate,diag_tickTime + 3];
VCM_CoordSerial = 1 + (missionNamespace getVariable ["VCM_CoordSerial",0]);
private _key = [time,VCM_CoordSerial];
private _dispatch = {
    params ["_arguments","_function","_destination"];
    if (_destination == 2) then {_arguments spawn (missionNamespace getVariable _function)} else {_arguments remoteExec [_function,_destination]};
};
private _issued = false;
if (_kind == "squads" && {VCM_MULTISQUAD}) then {
    private _sideKey = format ["squads:%1",side _caller];
    if (diag_tickTime >= (VCM_CoordTimes getOrDefault [_sideKey,-1])) then {
        private _groups = allGroups select {
            [_x] call VCM_fnc_CoordReady && {isNull objectParent leader _x} &&
            {leader _x distance2D leader _caller < VCM_COORDRANGE} &&
            {[side _caller,side _x] call BIS_fnc_sideIsFriendly} &&
            {{alive _x && {isNull objectParent _x}} count units _x >= 4} &&
            {"ItemRadio" in assignedItems leader _x}
        };
        _groups = [_groups,[],{leader _x distance2D _point},"ASCEND"] call BIS_fnc_sortBy;
        _groups = _groups select [0,3];
        if (count _groups >= 2) then {
            {
                private _role = ["assault","support","flank"] select _forEachIndex;
                private _angle = _point getDir getPosATL leader _x;
                private _goal = _point getPos [60,_angle + ([0,0,70] select _forEachIndex)];
                private _expiry = time + 35;
                _x setVariable ["VCM_CoordMission",[_key,_role,_expiry,groupOwner _x],true];
                [[_x,_role,_goal,_enemy,_point,_key,_expiry],"VCM_fnc_TeamAssign",groupOwner _x] call _dispatch;
            } forEach _groups;
            VCM_CoordTimes set [_sideKey,diag_tickTime + VCM_COORDCOOLDOWN];
            _issued = true;
        };
    };
};
if (_kind == "at" && {VCM_ATCOORD} && {_enemy isKindOf "LandVehicle"} &&
    {leader _caller distance2D _point <= VCM_ATRANGE} && {time >= ((_enemy getVariable ["VCM_ATLease",[]]) param [1,-1])}) then {
    private _launchers = (units _caller) select {alive _x && {!isPlayer _x} && {isNull objectParent _x} && {secondaryWeapon _x != ""}};
    _launchers = _launchers select {private _launcher = secondaryWeapon _x; _x ammo _launcher > 0 || {(magazines _x) arrayIntersect compatibleMagazines _launcher isNotEqualTo []}};
    if (_launchers isNotEqualTo []) then {
        private _shooter = _launchers select 0;
        private _expiry = time + VCM_ATLEASE;
        _enemy setVariable ["VCM_ATLease",[_shooter,_expiry,_key,_owner],true];
        _enemy setVariable ["VCM_ATFired",[_key,0],true];
        _caller setVariable ["VCM_CoordMission",[_key,"antitank",_expiry,_owner],true];
        [[_caller,_shooter,_enemy,_point,_key,_expiry],"VCM_fnc_ATAssign",_owner] call _dispatch;
        _issued = true;
    };
};
if (_kind == "escort" && {VCM_CROSSOWNER_ESCORT} && {VCM_COMBINEDARMS}) then {
    private _vehicles = vehicles select {
        private _crew = group driver _x;
        (_asset isEqualTo objNull || {_x == _asset}) && {_x isKindOf "LandVehicle"} && {!(_x isKindOf "StaticWeapon")} &&
        {alive _x} && {canMove _x} && {alive driver _x} && {groupOwner _crew != _owner} &&
        {_crew != _caller} && {[_crew] call VCM_fnc_CoordReady} &&
        {[side _caller,side _crew] call BIS_fnc_sideIsFriendly} && {leader _caller distance2D _x < 80} &&
        {getNumber (configOf _x >> "artilleryScanner") != 1} && {_x getVariable ["VCM_InfantryPartner",[]] isEqualTo []}
    };
    if (_vehicles isNotEqualTo [] && {count units _caller >= 2}) then {
        private _vehicle = _vehicles select 0;
        private _crew = group driver _vehicle;
        private _standoff = _point getPos [VCM_DISEMBARKRANGE max 150,_point getDir getPosATL _vehicle];
        private _stage = (_vehicle getPos [(_vehicle distance2D _standoff) min 60,_vehicle getDir _standoff]) findEmptyPosition [0,8,typeOf _vehicle];
        if (_stage isNotEqualTo [] && {!surfaceIsWater _stage}) then {
            private _expiry = time + 45;
            _caller setVariable ["VCM_CoordMission",[_key,"escort",_expiry,_owner],true];
            _crew setVariable ["VCM_CoordMission",[_key,"vehicle",_expiry,groupOwner _crew],true];
            _crew setVariable ["VCM_ArmorPartner",[_caller,_key],true];
            _vehicle setVariable ["VCM_InfantryPartner",[_caller,_key,_expiry,"remote"],true];
            [[_crew,_caller,_vehicle,_stage,_point,_key,_expiry,_owner],"VCM_fnc_VehicleAssist",owner _vehicle] call _dispatch;
            [[_caller,_crew,_vehicle,_stage,_enemy,_point,_key,_expiry,groupOwner _crew],"VCM_fnc_InfantryAssist",_owner] call _dispatch;
            _issued = true;
        };
    };
};
[_caller,"coord-request",format ["%1 issued=%2",_kind,_issued]] call VCM_fnc_DebugTrace;
_issued
