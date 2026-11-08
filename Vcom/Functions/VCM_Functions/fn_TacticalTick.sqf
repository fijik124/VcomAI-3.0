params ["_group"];
private _strength = {alive _x} count units _group;
private _peak = _group getVariable ["VCM_PeakStrength",0];
if (_strength > _peak) then {_group setVariable ["VCM_PeakStrength",_strength,true]};
if (_group getVariable ["VCM_NOAUTOTACTICS",false]) exitWith {};
if (time < ((_group getVariable ["VCM_CoordMission",[]]) param [2,-1])) exitWith {};
if (_strength < 2 || {_group getVariable ["VCM_Task",[]] isNotEqualTo []} || {_group getVariable ["VCM_NOFLANK",false]}) exitWith {};
private _evac = [_group] call VCM_fnc_EvacPlan;
if (_evac isNotEqualTo []) exitWith {[_group,_evac] spawn VCM_fnc_Evacuate};
private _retreat = [_group] call VCM_fnc_RetreatPlan;
if (_retreat isNotEqualTo [] && {_group getVariable ["VCM_Task",[]] isEqualTo []}) then {
    private _bound = _group getVariable ["VCM_BoundState",[]];
    if (_bound isNotEqualTo []) then {[_group,_bound select 0,"withdrawal"] call VCM_fnc_EndFireMove};
};
if (_retreat isNotEqualTo [] && {[_group] call VCM_fnc_TacticalReady}) exitWith {[_group,_retreat] spawn VCM_fnc_Retreat};
if (!([_group] call VCM_fnc_TacticalReady)) exitWith {};
private _enemy = leader _group call VCM_fnc_ClstEmy;
private _contact = [leader _group,_enemy] call VCM_fnc_ContactPosition;
if (_contact isEqualTo []) exitWith {};
private _send = {
    params ["_kind",["_target",_enemy],["_position",_contact],["_asset",objNull]];
    private _request = [_group,_kind,_target,_position,_asset,player];
    if (isServer) then {_request call VCM_fnc_CoordRequest} else {_request remoteExecCall ["VCM_fnc_CoordRequest",2]};
};
private _requested = false;
if (VCM_ATCOORD && {diag_tickTime >= (_group getVariable ["VCM_NextAT",-1])} &&
    {(units _group) findIf {secondaryWeapon _x != "" && {alive _x}} >= 0}) then {
    private _armor = (([leader _group] call VCM_fnc_KnownContacts) select {
        private _target = _x select 4;
        !isNull _target && {alive _target} && {_target isKindOf "LandVehicle"} &&
        {[side _group,_x select 2] call BIS_fnc_sideIsEnemy} && {!captive _target}
    }) apply {_x select 4};
    if (_armor isNotEqualTo []) then {
        private _target = _armor select 0;
        private _position = [leader _group,_target] call VCM_fnc_ContactPosition;
        if (_position isNotEqualTo [] && {leader _group distance2D _position <= VCM_ATRANGE} &&
            {time >= ((_target getVariable ["VCM_ATLease",[]]) param [1,-1])}) then {
            _group setVariable ["VCM_NextAT",diag_tickTime + 5];
            ["at",_target,_position] call _send;
            _requested = true;
        };
    };
};
if (_requested) exitWith {};
private _clear = [_group,_enemy] call VCM_fnc_ClearBuildingPlan;
if (_clear isNotEqualTo []) exitWith {[_group,_enemy] spawn VCM_fnc_ClearBuilding};
private _escort = [_group] call VCM_fnc_CombinedArmsPlan;
if (_escort isNotEqualTo []) exitWith {[_group,_escort] spawn VCM_fnc_CombinedArms};
if (VCM_CROSSOWNER_ESCORT && {VCM_COMBINEDARMS} && {diag_tickTime >= (_group getVariable ["VCM_NextEscort",-1])}) then {
    private _vehicles = (leader _group nearEntities ["LandVehicle",80]) select {
        alive driver _x && {groupOwner group driver _x != clientOwner} &&
        {[side _group,side group driver _x] call BIS_fnc_sideIsFriendly} &&
        {_x getVariable ["VCM_InfantryPartner",[]] isEqualTo []}
    };
    if (_vehicles isNotEqualTo []) then {
        _group setVariable ["VCM_NextEscort",diag_tickTime + 10];
        ["escort",_enemy,_contact,_vehicles select 0] call _send;
        _requested = true;
    };
};
if (_requested) exitWith {};
if (VCM_MULTISQUAD && {diag_tickTime >= (_group getVariable ["VCM_NextCoord",-1])} &&
    {count ([_group] call VCM_fnc_TacticalUnits) >= 4}) then {
    private _peers = allGroups select {_x != _group && {[_x] call VCM_fnc_CoordReady} &&
        {[side _group,side _x] call BIS_fnc_sideIsFriendly} && {leader _x distance2D leader _group < VCM_COORDRANGE} && {count units _x >= 4}};
    if (_peers isNotEqualTo []) then {
        _group setVariable ["VCM_NextCoord",diag_tickTime + VCM_COORDCOOLDOWN];
        ["squads"] call _send;
        _requested = true;
    };
};
if (_requested) exitWith {};
if (VCM_REACTIVESUPPRESSION && {diag_tickTime >= (_group getVariable ["VCM_SuppressAfter",-1])}) then {
    private _units = [_group] call VCM_fnc_TacticalUnits;
    private _pressured = _units findIf {getSuppression _x >= 0.35};
    if (count _units >= 4 && {_pressured >= 0} && {leader _group distance2D _contact < 400}) exitWith {
        private _support = (_units select {getSuppression _x < 0.35 && {!(_x getUnitTrait "Medic")}}) select [0,2];
        if (_support isNotEqualTo []) then {
            _group setVariable ["VCM_SuppressAfter",diag_tickTime + 12];
            [_group,"suppress",[[_support,[],[],3,_contact]],_enemy,_contact] spawn VCM_fnc_RunTactical;
        };
    };
};
