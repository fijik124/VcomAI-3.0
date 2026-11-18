/* Test-only, server-originated local work on the current group owner. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params ["_operation", "_group", "_label", ["_position", []]];
if (!local _group) exitWith {};
private _unit = leader _group;
private _run = _group getVariable ["VCM_RunId", []];
switch (_operation) do {
    case "prepareReaction": {
        {_x disableAI "AUTOTARGET"; _x setUnitPos "MIDDLE"; _x forceSpeed 2} forEach units _group;
    };
    case "fireCivilian": {
        _unit disableAI "TARGET";
        _unit disableAI "AUTOTARGET";
        _unit setVariable ["VCM_FTH",-100];
        _unit forceWeaponFire [currentWeapon _unit,"Single"];
    };
    case "forgeCivilian": {[_unit] remoteExecCall ["VCM_fnc_CivilianDanger",_position select 0]};
    case "surrender": {
        [_group,_position select 0] spawn {
            params ["_group","_enemy"];
            _group reveal [_enemy,4];
            sleep 0.5;
            _group setVariable ["VCM_SurrenderAfter",-1,true];
            _group setVariable ["VCM_TestSurrender",[_group] call VCM_fnc_Surrender,true];
        };
    };
    case "doctrinePost": {
        [_group] call VCM_fnc_CommandTick;
        _group setVariable ["VCM_NextTactic",1e9];
        _group setVariable ["VCM_ObjectiveAfter",-1];
        private _plan = [_group] call VCM_fnc_ObjectivePlan;
        _group setVariable ["VCM_TestDoctrinePlan",_plan,true];
        if (_plan isNotEqualTo []) then {[_group,_plan] spawn VCM_fnc_ObjectiveTask};
    };
    case "dangerMemory": {[_group,getPosATL _unit,1,"incoming fire"] call VCM_fnc_DangerRemember};
    case "forgedCommander": {
        private _identity = if (_position param [0,false]) then {objNull} else {player};
        [_identity,"doctrine","assault",[_group],getPosATL _unit,0,10] remoteExecCall ["VCM_fnc_CommanderRequest",2];
    };
    case "reconReport": {
        _position params ["_enemy",["_claimed",_group],["_nullIdentity",false]];
        [_group,_enemy,_claimed,_nullIdentity] spawn {
            params ["_group","_enemy","_claimed","_nullIdentity"];
            _group reveal [_enemy,4]; sleep 0.3;
            private _point = [leader _group,_enemy] call VCM_fnc_ContactPosition;
            private _identity = if (_nullIdentity) then {objNull} else {player};
            if (_point isNotEqualTo []) then {[_claimed,[[_enemy,_point]],_identity] remoteExecCall ["VCM_fnc_ReconReport",2]};
        };
    };
    case "requestCoord": {
        _position params ["_enemy","_point","_kind",["_claimed",_group],["_asset",objNull]];
        _group reveal [_enemy,4];
        [_claimed,_kind,_enemy,_point,_asset,player] remoteExecCall ["VCM_fnc_CoordRequest",2];
    };
    case "mountDriver": {
        private _vehicle = _position select 0;
        _group setVariable ["Vcm_Disable",false,true];
        _group addVehicle _vehicle;
        _unit assignAsDriver _vehicle;
        _unit moveInDriver _vehicle;
        _group call VCM_fnc_SquadExc;
    };
    case "attachPatient": {
        private _patient = _position select 0;
        doStop _unit;
        doStop _patient;
        _patient setPosATL (_unit getPos [1,90]);
        _patient setUnconscious true;
        [_group,_unit,_patient] spawn {
            params ["_group","_unit","_patient"];
            sleep 0.3;
            private _attached = [_group,[_group getVariable ["VCM_RunId",[]],900],_unit,_patient] call VCM_fnc_EvacAttach;
            _group setVariable ["VCM_TestEvacDiag",[_attached,local _unit,local _patient,_unit distance _patient,lifeState _patient,attachedTo _patient,VCM_CASEVAC],true];
        };
    };
    case "releaseHold": {
        {if (waypointType _x == "HOLD") then {_x setWaypointType "MOVE"}} forEach waypoints _group;
    };
    case "move": {
        [_unit, _position, _run, _label] spawn {
            params ["_unit", "_position", "_run", "_label"];
            private _arrived = [_unit, _position, 60] call VCM_fnc_MoveTo;
            private _payload = [_arrived, _run, local _unit];
            if (isServer) then {[2, objNull, _label, _payload] call VCM_test_fnc_Report} else {
                [clientOwner, player, _label, _payload] remoteExecCall ["VCM_test_fnc_Report", 2];
            };
        };
    };
    case "garrison": {_group spawn VCM_fnc_Garrison};
    case "deploy": {[_unit, backpack _unit, _run] spawn VCM_fnc_DeployStatic};
    case "bound": {[_unit] spawn VCM_fnc_FireMove};
    case "leaveBarracks": {_unit setPosATL _position};
    case "requestSupport": {
        _position params ["_enemy","_point","_kind",["_claimed",_group]];
        _group reveal [_enemy,4];
        [_claimed,_enemy,_point,_kind,player,4] remoteExecCall ["VCM_fnc_SupportRequest",2];
    };
    case "artilleryCounter": {
        private _gun = vehicle _unit;
        _gun setVariable ["VCM_TestArtyShots",0,true];
        _gun addEventHandler ["Fired",{private _gun = _this select 0; _gun setVariable ["VCM_TestArtyShots",1 + (_gun getVariable ["VCM_TestArtyShots",0]),true]}];
    };
    case "mountArtillery": {
        private _gun = _position select 0;
        _group setVariable ["Vcm_Disable",false,true];
        _group addVehicle _gun;
        _unit assignAsGunner _gun;
        _unit moveInGunner _gun;
        _group call VCM_fnc_SquadExc;
    };
};
