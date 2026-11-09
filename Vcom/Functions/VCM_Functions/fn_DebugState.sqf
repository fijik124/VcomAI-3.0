/* Owner-side snapshot. Drawing clients never query another owner's private movement or room graph. */
params ["_group"];
if (!VCM_Debug || {!local _group}) exitWith {[]};
private _rows = [];
private _route = [];
{
    private _unit = _x;
    private _command = currentCommand _unit;
    private _moving = _unit getVariable ["VCM_MoveKey",[]] isNotEqualTo [] || {_command == "MOVE"};
    private _goal = if (_moving) then {(expectedDestination _unit) select 0} else {[]};
    private _reasons = [];
    if (_unit getVariable ["VCM_FireLock",[]] isNotEqualTo []) then {_reasons pushBack "VCOM firing safety hold"};
    if (!(_unit checkAIFeature "PATH")) then {_reasons pushBack "PATH disabled"};
    if (lifeState _unit == "INCAPACITATED") then {_reasons pushBack "incapacitated"};
    private _recovery = _unit getVariable ["VCM_LastRecovery",[]];
    if (time - (_recovery param [3,-100]) < 10) then {_reasons pushBack format ["route retry %1",_recovery select 0]};
    _rows pushBack [_unit,_command,_goal,behaviour _unit,round (100 * getSuppression _unit),_reasons];
    private _planned = _unit getVariable ["VCM_DebugCQBRoute",[]];
    if (_planned isNotEqualTo [] && {(_planned select 0) isEqualTo (_unit getVariable ["VCM_TaskKey",[]])} &&
        {_unit getVariable ["VCM_MoveKey",[]] isNotEqualTo []}) then {_route = [_unit,_planned select 1,(_planned select 2) select [0,32]]};
} forEach ((units _group) select [0,64]);
private _rooms = [];
private _doors = [];
private _progress = _group getVariable ["VCM_CQBProgress",[]];
if (count _progress >= 11) then {
    private _building = _progress select 1;
    private _layout = _building getVariable ["VCM_CQBLayout",[]];
    if (_layout isNotEqualTo []) then {
        private _points = _layout select 0;
        {
            private _id = _forEachIndex;
            private _center = [0,0,0];
            {_center = _center vectorAdd (_points select _x select 0)} forEach _x;
            _center = _center vectorMultiply (1 / count _x);
            private _blocked = (_progress select 6) findIf {(_x select 0) == _id};
            private _status = "pending";
            if ((_progress select 2) == "searching" && {_progress select 3 == _id}) then {_status = "searching"};
            if (_id in (_progress select 5)) then {_status = "searched"};
            if (_blocked >= 0) then {_status = (_progress select 6 select _blocked) select 1};
            _rooms pushBack [_center,_id,_status,count (_x arrayIntersect (_progress select 7)),count _x];
        } forEach ((_layout select 3) select [0,32]);
        {
            _x params ["_number","_source","_position"];
            private _status = if (_building animationSourcePhase _source >= 0.65) then {"open"} else {
                if ((_building getVariable [format ["bis_disabled_Door_%1",_number],0]) in [0,false]) then {"closed"} else {"locked"}
            };
            _doors pushBack [_position,_number,_status];
        } forEach ((_layout select 4) select [0,48]);
    };
};
[time,_group getVariable ["VCM_DebugDecision",[]],_rows,_route,_rooms,_doors]
