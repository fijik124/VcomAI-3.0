/* Two moving teams establish an observation post or a defense with individual watch sectors. */
params ["_group","_plan"];
if (_plan isEqualTo [] || {!([_group] call VCM_fnc_TacticalReady)}) exitWith {false};
_plan params ["_order","_units","_positions","_enemy","_watch"];
private _kind = _order select 1;
private _half = ceil (count _units / 2);
private _first = _units select [0,_half];
private _second = _units - _first;
private _sectors = [];
{
    private _sector = _watch;
    if (_kind in ["defend","fallback"]) then {
        private _angle = (_order select 3) + ([-60,0,60,180] select (_forEachIndex mod 4));
        _sector = (_positions select _forEachIndex) getPos [100,_angle];
    };
    _sectors pushBack _sector;
} forEach _units;
_group setVariable ["VCM_ObjectiveAfter",diag_tickTime + VCM_POINTINTERVAL];
private _result = [_group,_kind,[
    [_first,_second,_positions select [_half],VCM_POINTSECONDS,_watch],
    [_second,_first,_positions select [0,_half],VCM_POINTSECONDS,_watch],
    [_units,[],[],VCM_POINTSCAN,_watch]
],_enemy,_watch,[+_order,_sectors,_group getVariable ["VCM_CommandRevision",0],_units]] call VCM_fnc_RunTactical;
if (_result) then {_group setVariable ["VCM_LastObjective",[+_order,time,_positions],true]};
_result
