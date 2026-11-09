/* Called by the existing human-state timer. Draw3D reads a bounded cached unit list. */
if (!hasInterface) exitWith {};
private _handler = missionNamespace getVariable ["VCM_DebugDrawID",-1];
if (!VCM_DEBUGOVERLAY) exitWith {
    if (_handler >= 0) then {
        removeMissionEventHandler ["Draw3D",_handler];
        VCM_DebugDrawID = -1;
        VCM_DebugVisible = [];
        VCM_DebugLines = []; VCM_DebugMarkers = [];
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
        {drawLine3D _x} forEach (missionNamespace getVariable ["VCM_DebugLines",[]]);
        {
            _x params ["_point","_text","_color"];
            drawIcon3D ["\a3\ui_f\data\map\markers\military\dot_CA.paa",_color,_point,0.5,0.5,0,_text,1,0.026,"RobotoCondensed"];
        } forEach (missionNamespace getVariable ["VCM_DebugMarkers",[]]);
    }];
};
if (diag_tickTime < (missionNamespace getVariable ["VCM_DebugNextUI",-1])) exitWith {};
VCM_DebugNextUI = diag_tickTime + VCM_DEBUGINTERVAL;
if (!VCM_Debug) exitWith {VCM_DebugVisible = []; VCM_DebugLines = []; VCM_DebugMarkers = []; hintSilent "VCOM debugger: enable server telemetry and event log in Addon Options."};
private _center = getPosATL cameraOn;
private _groups = allGroups select {leader _x distance2D _center <= VCM_DEBUGDISTANCE && {_x getVariable ["VCM_DebugInfo",[]] isNotEqualTo []}};
_groups = [_groups,[],{leader _x distance2D _center},"ASCEND"] call BIS_fnc_sortBy;
private _visible = [];
private _selected = group cursorObject;
if (!(_selected in _groups)) then {_selected = _groups param [0,grpNull]};
{
    private _group = _x;
    private _info = _group getVariable ["VCM_DebugInfo",[]];
    private _snapshot = _group getVariable ["VCM_DebugState",[]];
    private _rows = if (time - (_snapshot param [0,-100]) < 10) then {_snapshot param [2,[]]} else {[]};
    if (time - (_info param [9,-100]) < 10) then {
        {
            if (count _visible >= floor VCM_DEBUGUNITS) exitWith {};
            private _role = (_x getVariable ["VCM_TaskRole",[]]) param [1,""];
            private _sector = _x getVariable ["VCM_CQBSector",[]];
            if ((_info select 2) == "clear" && {_sector isNotEqualTo []}) then {_role = format ["%1 room %2",_role,1 + (_sector select 1)]};
            private _boundKey = _x getVariable ["VCM_BoundKey",[]];
            if (_boundKey isNotEqualTo []) then {
                private _boundRole = _x getVariable ["VCM_DebugBoundRole",[]];
                _role = if ((_boundRole param [0,[]]) isEqualTo _boundKey) then {_boundRole select 1} else {"bound"};
            };
            private _unit = _x;
            private _rowIndex = _rows findIf {(_x select 0) == _unit};
            private _row = _rows param [_rowIndex max 0,[]];
            if (_rowIndex < 0) then {_row = []};
            private _destination = if (VCM_DEBUGPLANS) then {_row param [2,[]]} else {[]};
            private _color = [[0.2,0.8,1,1],[1,0.7,0.1,1]] select (_role == "move");
            _visible pushBack [_x,format ["%1 | %2 %3 | %4 %5 | pressure %6%% | %7",groupId _group,_info select 2,_role,
                _row param [1,""],_row param [3,""],_row param [4,0],(_row param [5,[]]) joinString ", "],_destination,_color];
        } forEach units _group;
    };
    if (count _visible >= floor VCM_DEBUGUNITS) exitWith {};
} forEach _groups;
VCM_DebugVisible = _visible;
private _snapshot = _selected getVariable ["VCM_DebugState",[]];
if (time - (_snapshot param [0,-100]) >= 10) then {_snapshot = []};
private _decision = _snapshot param [1,[]];
private _markers = [];
private _lines = [];
if (VCM_DEBUGPLANS) then {
    private _goal = _decision param [3,[]];
    private _contact = _decision param [4,[]];
    if (_goal isNotEqualTo []) then {_markers pushBack [_goal vectorAdd [0,0,1],"INTENDED GOAL",[1,0.8,0,1]]};
    if (_contact isNotEqualTo []) then {_markers pushBack [_contact vectorAdd [0,0,1],"REMEMBERED THREAT",[1,0.3,0.3,1]]};
    private _route = _snapshot param [3,[]];
    if (_route isNotEqualTo [] && {!isNull (_route select 0)}) then {
        private _last = getPosATLVisual (_route select 0) vectorAdd [0,0,0.3];
        {
            private _point = _x vectorAdd [0,0,0.3];
            _lines pushBack [_last,_point,[0.1,1,1,1]]; _last = _point;
        } forEach (_route select 2);
    };
};
if (VCM_DEBUGROOMS) then {
    {
        _x params ["_point","_id","_status","_covered","_total"];
        private _color = switch (_status) do {
            case "searched": {[0.2,1,0.3,1]}; case "searching": {[1,0.8,0,1]};
            case "pending": {[0.7,0.7,0.7,1]}; default {[1,0.2,0.2,1]};
        };
        _markers pushBack [_point vectorAdd [0,0,1.2],format ["ROOM %1: %2 %3/%4",_id + 1,_status,_covered,_total],_color];
    } forEach (_snapshot param [4,[]]);
    {
        _x params ["_point","_id","_status"];
        private _color = switch (_status) do {case "open": {[0.2,1,0.3,1]}; case "locked": {[1,0.2,0.2,1]}; default {[1,0.8,0,1]}};
        _markers pushBack [_point,format ["DOOR %1: %2",_id,_status],_color];
    } forEach (_snapshot param [5,[]]);
};
VCM_DebugLines = _lines;
VCM_DebugMarkers = _markers select {(_x select 0) distance2D _center <= VCM_DEBUGDISTANCE};
private _info = _selected getVariable ["VCM_DebugInfo",[]];
private _cqb = _selected getVariable ["VCM_CQBProgress",[]];
private _roomText = if (count _cqb >= 11) then {format ["<br/>Room search: %1 | room %2 | searched %3/%4 | blocked %5 | %6",_cqb select 2,1 + (_cqb select 3),count (_cqb select 5),_cqb select 4,count (_cqb select 6),_cqb select 10]} else {""};
hintSilent parseText format ["<t color='#55ccff'>VCOM Edited by Fijik - debugger</t><br/>Local FPS: %1 | shown: %2 units<br/>Group: %3 | owner: %4 | owner FPS: %5<br/>Task: %6 phase %7<br/>Planning: %8 ms / %9 seconds<br/>Last result: %10<br/>Recent events: %11<br/>Counters: %12%13<br/>Intent: %14<br/>Why: %15<br/>Point at a squad to inspect it. Cyan: planned CQB route; yellow: goal; red: remembered threat.",
    round diag_fps,count _visible,groupId _selected,_info param [0,-1],round (_info param [1,0]),
    _info param [2,"idle"],_info param [3,0],_info param [5,0],_info param [6,0],
    _info param [4,[]],_info param [7,[]],_info param [8,[]],_roomText,_decision param [1,"native / no recorded decision"],_decision param [2,""]];
