/* Called by the existing human-state timer. Draw3D reads a bounded cached unit list. */
if (!hasInterface) exitWith {};
disableSerialization;
VCM_DebugUIReady = true;
private _handler = missionNamespace getVariable ["VCM_DebugDrawID",-1];
if (!VCM_DEBUGOVERLAY || {!VCM_Debug}) exitWith {
    if (_handler >= 0) then {
        removeMissionEventHandler ["Draw3D",_handler];
        VCM_DebugDrawID = -1;
    };
    VCM_DebugVisible = [];
    VCM_DebugLines = []; VCM_DebugMarkers = [];
    private _status = if (VCM_DEBUGOVERLAY && {diag_tickTime < (missionNamespace getVariable ["VCM_DebugStatusUntil",-1])}) then {
        "<t color='#55ccff'>VCOM AI debugger</t><br/>Enable <t color='#ffcc55'>Enable AI debugger and telemetry</t> in server/mission Addon Options, under 18 Debugger and Telemetry."
    } else {""};
    [_status] call VCM_fnc_DebugPanel;
};
if (!(missionNamespace getVariable ["VCM_SettingsReady",false])) exitWith {
    ["<t color='#55ccff'>VCOM AI debugger</t><br/>Waiting for server settings. Check that VCOM is loaded and allowed by the mission on the server."] call VCM_fnc_DebugPanel;
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
private _display = findDisplay 312;
if (isNull _display) then {_display = findDisplay 46};
private _panel = uiNamespace getVariable ["VCM_DebugPanel",controlNull];
private _displayChanged = isNull _panel || {ctrlParent _panel != _display};
if (!_displayChanged && {diag_tickTime < (missionNamespace getVariable ["VCM_DebugNextUI",-1])}) exitWith {};
VCM_DebugNextUI = diag_tickTime + VCM_DEBUGINTERVAL;
private _center = positionCameraToWorld [0,0,0];
VCM_DebugCameraPosition = _center;
private _groups = allGroups select {
    alive leader _x && {leader _x distance2D _center <= VCM_DEBUGDISTANCE} &&
    {time - ((_x getVariable ["VCM_DebugInfo",[]]) param [9,-100]) < 10}
};
_groups = [_groups,[],{leader _x distance2D _center},"ASCEND"] call BIS_fnc_sortBy;
private _visible = [];
private _selected = group cursorObject;
if (!isNull findDisplay 312) then {
    private _selection = curatorSelected;
    private _selectedGroups = +(_selection param [1,[]]);
    {_selectedGroups pushBackUnique group _x} forEach (_selection param [0,[]]);
    private _index = _selectedGroups findIf {_x in _groups};
    if (_index >= 0) then {_selected = _selectedGroups select _index};
};
if (!(_selected in _groups)) then {_selected = _groups param [0,grpNull]};
VCM_DebugSelectedGroup = _selected;
if (isNull _selected || {!Vcm_ActivateAI}) exitWith {
    VCM_DebugVisible = []; VCM_DebugLines = []; VCM_DebugMarkers = [];
    private _status = if (!Vcm_ActivateAI) then {"VCOM AI is disabled in server/mission Addon Options."} else {
        format ["Waiting for fresh AI telemetry within %1 m of the camera.<br/>Move closer to an active VCOM squad or increase the debugger draw distance.",round VCM_DEBUGDISTANCE]
    };
    ["<t color='#55ccff'>VCOM AI debugger</t><br/>" + _status] call VCM_fnc_DebugPanel;
};
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
        } forEach ((units _group) select {alive _x && {_x distance2D _center <= VCM_DEBUGDISTANCE}});
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
private _escape = {
    private _text = if (_this isEqualType "") then {_this} else {str _this};
    ((toArray _text) apply {switch (_x) do {
        case 38: {"&amp;"}; case 60: {"&lt;"}; case 62: {"&gt;"}; default {toString [_x]};
    }}) joinString ""
};
private _history = _info param [7,[]];
private _events = ((_history select [(count _history - 3) max 0,3]) apply {
    format ["%1: %2",(_x param [1,""]) call _escape,((_x param [2,""]) select [0,80]) call _escape]
}) joinString "<br/>";
private _counters = ((_info param [8,[]]) select [0,6]) apply {format ["%1: %2",_x select 0,_x select 1]};
private _last = _info param [4,[]];
private _result = if (_last isEqualTo []) then {"none"} else {format ["%1: %2",_last param [0,""],_last param [1,""]]};
private _text = format ["<t color='#55ccff'>VCOM Edited by Fijik - debugger</t><br/>Local FPS: %1 | shown: %2 units<br/>Group: %3 | owner: %4 | owner FPS: %5<br/>Task: %6 phase %7<br/>Planning: %8 ms / %9 seconds<br/>Last result: %10<br/>Recent events:<br/>%11<br/>Counters: %12%13<br/>Intent: %14<br/>Why: %15<br/>Point at a squad or select it in Zeus. Cyan: planned CQB route; yellow: goal; red: remembered threat.",
    round diag_fps,count _visible,(groupId _selected) call _escape,_info param [0,-1],round (_info param [1,0]),
    _info param [2,"idle"],_info param [3,0],_info param [5,0],_info param [6,0],
    _result call _escape,_events,(_counters joinString ", ") call _escape,_roomText,
    (_decision param [1,"native / no recorded decision"]) call _escape,((_decision param [2,""]) select [0,200]) call _escape];
[_text] call VCM_fnc_DebugPanel;
