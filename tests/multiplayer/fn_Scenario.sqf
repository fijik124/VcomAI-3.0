/* Test-only, server-originated local work on the current group owner. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params ["_operation", "_group", "_label", ["_position", []]];
if (!local _group) exitWith {};
private _unit = leader _group;
private _run = _group getVariable ["VCM_RunId", []];
switch (_operation) do {
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
            _group setVariable ["VCM_TestEvacDiag",[_attached,local _unit,local _patient,_unit distance _patient,lifeState _patient,attachedTo _patient,VCM_MEDICALACTIVE,VCM_ACECASEVAC],true];
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
