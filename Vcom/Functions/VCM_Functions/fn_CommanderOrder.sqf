/* Server-only order implementation. Deliberately absent from CfgRemoteExec. */
if (!isServer) exitWith {false};
params [["_identity",objNull,[objNull]],["_action","",[""]],["_kind","",[""]],
    ["_groups",[],[[]]],["_position",[],[[]]],["_direction",0,[0]],["_radius",30,[0]]];
if ((!VCM_COMMANDPOINTS && {!(_action in ["resetPoint","resetGroup","resetDanger"])}) ||
    {!(_action in ["point","restartPoint","resetPoint","resetGroup","resetDanger","doctrine","night"])} ||
    {count _groups > 16} || {_groups findIf {!(_x isEqualType grpNull) || {isNull _x}} >= 0} ||
    {count _position != 3} || {_position findIf {!(_x isEqualType 0) || {!finite _x}} >= 0} ||
    {!finite _direction} || {!finite _radius} || {abs (_position select 0) > 1e6} ||
    {abs (_position select 1) > 1e6} || {abs (_position select 2) > 2000}) exitWith {false};
if ((_action == "point" && {!(_kind in ["recon","defend","fallback","danger"])}) ||
    {_action == "doctrine" && {!(_kind in ["auto","default","recon","assault","defend","convoy"])}} ||
    {_action == "night" && {!(_kind in ["auto","blackout","illuminate"])}}) exitWith {false};
private _curator = objNull;
if (!isNull _identity) then {
    if (!isPlayer _identity) exitWith {};
    _curator = getAssignedCuratorLogic _identity;
};
if (!isNull _identity && {isNull _curator}) exitWith {false};
private _editable = if (isNull _curator) then {[]} else {curatorEditableObjects _curator};
private _canEdit = {
    params ["_group"];
    !isNull _group && {alive leader _group} && {!(isPlayer leader _group)} &&
    {side _group in VCM_SIDEENABLED} && {!(_group getVariable ["Vcm_Disable",false])} &&
    {isNull _curator || {leader _group in _editable}}
};
if (_groups findIf {!([_x] call _canEdit)} >= 0) exitWith {false};
if (!isNull _curator && {diag_tickTime < (_curator getVariable ["VCM_OrderAfter",-1])}) exitWith {false};
if (!isNull _curator) then {_curator setVariable ["VCM_OrderAfter",diag_tickTime + 0.2]};
private _points = (missionNamespace getVariable ["VCM_CommandPointRegistry",[]]) select {(_x select 5) findIf {!isNull _x && {alive leader _x}} >= 0};
_groups = _groups arrayIntersect _groups;
_radius = (_radius max 5) min 150;
private _touch = {
    params ["_group"];
    _group setVariable ["VCM_CommandRevision",1 + (_group getVariable ["VCM_CommandRevision",0]),true];
};
private _erase = {
    params ["_record"];
    _record params ["_id","_type","_point","_bearing","_size","_assigned"];
    {
        private _group = _x;
        private _field = if (_type == "fallback") then {"VCM_FallbackPoint"} else {"VCM_Objective"};
        if (_type == "danger") then {
            _group setVariable ["VCM_DangerPoints",(_group getVariable ["VCM_DangerPoints",[]]) select {_x select 0 != _id},true];
        } else {
            if (((_group getVariable [_field,[]]) param [0,""]) == _id) then {_group setVariable [_field,nil,true]};
        };
        [_group] call _touch;
    } forEach _assigned;
};
private _changed = false;
switch (_action) do {
    case "point": {
        if (_groups isEqualTo []) exitWith {};
        private _replaced = if (_kind == "danger") then {0} else {
            {_x getVariable [if (_kind == "fallback") then {"VCM_FallbackPoint"} else {"VCM_Objective"},[]] isNotEqualTo []} count _groups
        };
        if (count _points - _replaced + count _groups > 64) exitWith {};
        {
            private _group = _x;
            private _field = if (_kind == "fallback") then {"VCM_FallbackPoint"} else {"VCM_Objective"};
            private _old = if (_kind == "danger") then {[]} else {_group getVariable [_field,[]]};
            if (_old isNotEqualTo []) then {
                private _oldId = _old select 0;
                _points = _points select {_x select 0 != _oldId};
            };
            VCM_PointSerial = 1 + (missionNamespace getVariable ["VCM_PointSerial",0]);
            private _id = format ["VCM_POINT_%1",VCM_PointSerial];
            private _revision = 1 + (_group getVariable ["VCM_CommandRevision",0]);
            private _order = [_id,_kind,+_position,_direction,_radius,_revision];
            if (_kind == "danger") then {
                private _zones = +(_group getVariable ["VCM_DangerPoints",[]]);
                if (count _zones >= 8) then {
                    private _expired = (_zones deleteAt 0) select 0;
                    _points = _points select {_x select 0 != _expired};
                };
                _zones pushBack _order;
                _group setVariable ["VCM_DangerPoints",_zones,true];
            } else {_group setVariable [_field,_order,true]};
            _points pushBack [_id,_kind,+_position,_direction,_radius,[_group],_revision];
            [_group] call _touch;
            _changed = true;
        } forEach _groups;
    };
    case "resetPoint": {
        private _near = _points select {(_x select 2) distance2D _position <= 50 && {(_x select 5) findIf {!([_x] call _canEdit)} < 0}};
        if (_near isEqualTo []) exitWith {};
        _near = [_near,[],{(_x select 2) distance2D _position},"ASCEND"] call BIS_fnc_sortBy;
        private _center = _near select 0 select 2;
        private _removed = _near select {(_x select 2) distance2D _center < 3};
        {[_x] call _erase} forEach _removed;
        private _ids = _removed apply {_x select 0};
        _points = _points select {!(_x select 0 in _ids)};
        _changed = true;
    };
    case "restartPoint": {
        private _near = _points select {_x select 1 != "danger" && {(_x select 2) distance2D _position <= 50} &&
            {(_x select 5) findIf {!([_x] call _canEdit)} < 0}};
        if (_near isEqualTo []) exitWith {};
        _near = [_near,[],{(_x select 2) distance2D _position},"ASCEND"] call BIS_fnc_sortBy;
        private _center = _near select 0 select 2;
        {
            if ((_x select 2) distance2D _center < 3) then {
                private _record = _x;
                private _revision = 1 + (_record select 6);
                _record set [6,_revision];
                {
                    private _field = if (_record select 1 == "fallback") then {"VCM_FallbackPoint"} else {"VCM_Objective"};
                    private _order = +(_x getVariable [_field,[]]);
                    if (_order isNotEqualTo [] && {_order select 0 == _record select 0}) then {
                        _order set [5,_revision]; _x setVariable [_field,_order,true];
                        _x setVariable ["VCM_LastObjective",nil,true]; [_x] call _touch;
                    };
                } forEach (_record select 5);
                _changed = true;
            };
        } forEach _near;
    };
    case "resetGroup": {
        {
            private _group = _x;
            private _removed = _points select {_group in (_x select 5)};
            {[_x] call _erase} forEach _removed;
            private _ids = _removed apply {_x select 0};
            _points = _points select {!(_x select 0 in _ids)};
            _group setVariable ["VCM_Doctrine","auto",true];
            _group setVariable ["VCM_AutoRole","default",true];
            _group setVariable ["VCM_AutoRoleAfter",-1,true];
            _group setVariable ["VCM_NightMode","auto",true];
            _group setVariable ["VCM_DefenseAnchor",nil,true];
            _group setVariable ["VCM_ThreatAxis",nil,true];
            [_group] call _touch;
            _group setVariable ["VCM_MemoryReset",[_group getVariable ["VCM_CommandRevision",0],[],0],true];
            _changed = true;
        } forEach _groups;
    };
    case "resetDanger": {
        {
            [_x] call _touch;
            _x setVariable ["VCM_MemoryReset",[_x getVariable ["VCM_CommandRevision",0],+_position,_radius],true];
            _changed = true;
        } forEach _groups;
    };
    case "doctrine": {
        {
            _x setVariable ["VCM_Doctrine",_kind,true];
            _x setVariable ["VCM_DefenseAnchor",nil,true];
            [_x] call _touch; _changed = true;
        } forEach _groups;
    };
    case "night": {
        {_x setVariable ["VCM_NightMode",_kind,true]; [_x] call _touch; _changed = true} forEach _groups;
    };
};
if (_changed) then {
    VCM_CommandPointRegistry = _points select {(_x select 5) findIf {!isNull _x} >= 0};
    publicVariable "VCM_CommandPointRegistry";
};
_changed
