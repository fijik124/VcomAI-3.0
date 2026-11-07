/* Test-only, server-originated local work on the current group owner. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params ["_operation", "_group", "_label", ["_position", []]];
if (!local _group) exitWith {};
private _unit = leader _group;
private _run = _group getVariable ["VCM_RunId", []];
switch (_operation) do {
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
};
