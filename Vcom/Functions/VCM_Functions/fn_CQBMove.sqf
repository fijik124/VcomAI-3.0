/* Native navigation with a strict same-floor arrival check and live, nearby door checks. */
params ["_unit","_destination","_group","_key","_building","_doors","_deadline"];
private _run = _key select 0;
private _valid = {
    [_group,_run,_key,"clear"] call VCM_fnc_TacticalValid && {VCM_FULLCLEAR} && {VCM_CQBSECTORS} &&
    {alive _building} && {local _unit} && {lifeState _unit != "INCAPACITATED"} && {diag_tickTime < _deadline}
};
if (!call _valid) exitWith {false};
private _blocked = false;
private _nextDoors = -1;
private _guard = {
    if (!call _valid) exitWith {false};
    if (diag_tickTime >= _nextDoors) then {
        _nextDoors = diag_tickTime + 0.5;
        private _needed = ([_building,getPosATL _unit,_destination,_doors] call VCM_fnc_CQBLink) select 1;
        {
            _x params ["_number","_source","_point"];
            if (_unit distance2D _point < 3.5 && {abs ((getPosASL _unit select 2) - (ATLToASL _point select 2)) < 2}) then {
                private _locked = !((_building getVariable [format ["bis_disabled_Door_%1",_number],0]) in [0,false]);
                if (_locked && {_forEachIndex in _needed} && {_building animationSourcePhase _source < 0.65}) then {_blocked = true} else {
                    if (!_locked && {_building animationSourcePhase _source < 0.65}) then {
                        if (toLower _source find "_sound_" >= 0) then {[_building,_number,1] call BIS_fnc_Door} else {_building animateSource [_source,1]};
                        [_group,"cqb-door",str _number] call VCM_fnc_DebugTrace;
                    };
                };
            };
        } forEach _doors;
    };
    !_blocked
};
[_unit,_key] call VCM_fnc_MovementControl;
_unit setVariable ["VCM_CQBMoveKey",_key];
// Indoor path transitions and door interaction need the native FSM. Preserve a mission-disabled FSM.
private _saved = _unit getVariable ["VCM_MovementControl",[]];
if (_saved isNotEqualTo [] && {(_saved select 1) findIf {(_x select 0) == "FSM" && {_x select 1}} >= 0}) then {_unit enableAI "FSM"};
sleep 0.1;
private _timeout = ((_deadline - diag_tickTime) min VCM_CQBSECONDS) max 0.1;
private _arrived = [_unit,_destination,_timeout,_guard,_key,0.8] call VCM_fnc_MoveTo;
// Native AI has a stopping radius. Room membership is verified separately before granting coverage.
if (((_unit getVariable ["VCM_MovementControl",[]]) param [0,[]]) isEqualTo _key) then {[_unit] call VCM_fnc_MovementControl};
if ((_unit getVariable ["VCM_CQBMoveKey",[]]) isEqualTo _key) then {_unit setVariable ["VCM_CQBMoveKey",nil]};
private _inside = _arrived && {_unit distance _destination < 2.1} && {abs ((getPosASL _unit select 2) - (ATLToASL _destination select 2)) < 0.8};
if (!_inside || {_blocked}) then {[_group,"cqb-move-failed",if (_blocked) then {"locked-door"} else {str _destination}] call VCM_fnc_DebugTrace};
call _valid && {_inside} && {!_blocked}
