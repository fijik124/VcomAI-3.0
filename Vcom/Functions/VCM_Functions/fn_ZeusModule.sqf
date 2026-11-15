/* Native Eden/Zeus module entry. Zeus requests are validated again by the server. */
params [["_logic",objNull,[objNull]],["_units",[],[[]]],["_activated",true,[true]]];
if (!_activated || {isNull _logic} || {!local _logic}) exitWith {};
private _action = getText (configOf _logic >> "vcmCommand");
private _kind = getText (configOf _logic >> "vcmKind");
private _soldiers = _units apply {if (_x isKindOf "Man") then {_x} else {driver _x}};
private _groups = (_soldiers select {!isNull _x}) apply {group _x};
private _zeus = _logic getVariable ["BIS_fnc_moduleInit_isCuratorPlaced",false];
if (_zeus && {hasInterface}) then {
    private _hover = missionNamespace getVariable ["bis_fnc_curatorObjectPlaced_mouseOver",[""]];
    if ((_hover param [0,""]) == "OBJECT") then {
        private _object = _hover param [1,objNull];
        if (!isNull _object && {_object isKindOf "Man"}) then {_groups pushBack group _object};
        if (!isNull _object && {_object isKindOf "LandVehicle"} && {alive driver _object}) then {_groups pushBack group driver _object};
    };
    if (_groups isEqualTo []) then {
        private _saved = missionNamespace getVariable ["VCM_ZeusSelection",[-100,[]]];
        if (diag_tickTime - (_saved select 0) < 30) then {_groups = +(_saved select 1)};
    };
};
_groups = (_groups arrayIntersect _groups) select {!isNull _x && {side _x in [west,east,resistance]}};
if (_action in ["resetPoint","restartPoint"]) then {_groups = []};
private _request = [if (_zeus) then {player} else {objNull},_action,_kind,_groups,getPosATL _logic,getDir _logic,
    _logic getVariable ["VCM_Radius",VCM_POINTRADIUS]];
if (_zeus) then {
    if (_groups isEqualTo [] && {!(_action in ["resetPoint","restartPoint"])}) then {
        systemChat "VCOM: Select AI squads first, then place the module within 30 seconds, or drop it on a soldier.";
    } else {
        if (isServer) then {_request call VCM_fnc_CommanderOrder} else {_request remoteExecCall ["VCM_fnc_CommanderRequest",2]};
    };
} else {
    if (isServer) then {
        [_request] spawn {
            params ["_request"];
            waitUntil {sleep 0.1; missionNamespace getVariable ["VCM_ServerReady",false]};
            _request call VCM_fnc_CommanderOrder;
        };
    };
};
deleteVehicle _logic;
