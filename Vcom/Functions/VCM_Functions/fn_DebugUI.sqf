/* Called by the existing human-state timer. Draw3D reads a bounded cached unit list. */
if (!hasInterface) exitWith {};
private _handler = missionNamespace getVariable ["VCM_DebugDrawID",-1];
if (!VCM_DEBUGOVERLAY) exitWith {
    if (_handler >= 0) then {
        removeMissionEventHandler ["Draw3D",_handler];
        VCM_DebugDrawID = -1;
        VCM_DebugVisible = [];
        hintSilent "";
    };
};
if (_handler < 0) then {
    VCM_DebugDrawID = addMissionEventHandler ["Draw3D",{
        {
            _x params ["_unit","_label","_destination","_color"];
            if (!isNull _unit) then {
                private _position = getPosATLVisual _unit vectorAdd [0,0,2];
                drawIcon3D ["",_color,_position,0,0,0,_label,1,0.027,"RobotoCondensed"];
                if (_destination isNotEqualTo []) then {drawLine3D [_position,_destination vectorAdd [0,0,0.2],_color]};
            };
        } forEach (missionNamespace getVariable ["VCM_DebugVisible",[]]);
    }];
};
if (diag_tickTime < (missionNamespace getVariable ["VCM_DebugNextUI",-1])) exitWith {};
VCM_DebugNextUI = diag_tickTime + VCM_DEBUGINTERVAL;
if (!VCM_Debug) exitWith {VCM_DebugVisible = []; hintSilent "VCOM debugger: enable server telemetry and event log in Addon Options."};
private _center = getPosATL cameraOn;
private _groups = allGroups select {leader _x distance2D _center <= VCM_DEBUGDISTANCE && {_x getVariable ["VCM_DebugInfo",[]] isNotEqualTo []}};
_groups = [_groups,[],{leader _x distance2D _center},"ASCEND"] call BIS_fnc_sortBy;
private _visible = [];
private _selected = group cursorObject;
if (!(_selected in _groups)) then {_selected = _groups param [0,grpNull]};
{
    private _group = _x;
    private _info = _group getVariable ["VCM_DebugInfo",[]];
    if (time - (_info param [9,-100]) < 10) then {
        {
            if (count _visible >= floor VCM_DEBUGUNITS) exitWith {};
            private _role = (_x getVariable ["VCM_TaskRole",[]]) param [1,""];
            private _boundKey = _x getVariable ["VCM_BoundKey",[]];
            if (_boundKey isNotEqualTo []) then {
                private _boundRole = _x getVariable ["VCM_DebugBoundRole",[]];
                _role = if ((_boundRole param [0,[]]) isEqualTo _boundKey) then {_boundRole select 1} else {"bound"};
            };
            private _move = _x getVariable ["VCM_DebugMove",[]];
            private _destination = if (time - (_move param [0,-100]) < 60) then {_move param [1,[]]} else {[]};
            private _color = [[0.2,0.8,1,1],[1,0.7,0.1,1]] select (_role == "move");
            _visible pushBack [_x,format ["%1 | %2 %3 | owner %4 | %5",groupId _group,_info select 2,_role,_info select 0,lifeState _x],_destination,_color];
        } forEach units _group;
    };
    if (count _visible >= floor VCM_DEBUGUNITS) exitWith {};
} forEach _groups;
VCM_DebugVisible = _visible;
private _info = _selected getVariable ["VCM_DebugInfo",[]];
hintSilent parseText format ["<t color='#55ccff'>VCOM Edited by Fijik - debugger</t><br/>Local FPS: %1 | shown: %2 units<br/>Group: %3 | owner: %4 | owner FPS: %5<br/>Task: %6 phase %7<br/>Planning: %8 ms / %9 seconds<br/>Last result: %10<br/>Recent events: %11<br/>Counters: %12",
    round diag_fps,count _visible,groupId _selected,_info param [0,-1],round (_info param [1,0]),
    _info param [2,"idle"],_info param [3,0],_info param [5,0],_info param [6,0],
    _info param [4,[]],_info param [7,[]],_info param [8,[]]];
