/* Owner-local, bounded memory of observed incoming fire, casualties and failed outdoor movement. */
params ["_group","_position",["_weight",1],["_reason","fire"]];
if (!VCM_DANGERMEMORY || {!local _group} || {count _position != 3} ||
    {_position findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {false};
private _memory = (_group getVariable ["VCM_DangerMemory",[]]) select {(_x select 2) > time};
private _index = _memory findIf {(_x select 0) distance2D _position < VCM_DANGERRADIUS * 0.5 && {_x select 3 == _reason}};
private _strength = (_weight max 0.1) min 5;
if (_index >= 0) then {
    _strength = (_strength + (_memory select _index select 1)) min 5;
    _memory deleteAt _index;
};
_memory pushBack [+_position,_strength,time + VCM_DANGERTIME,_reason];
if (count _memory > floor VCM_DANGERMAX) then {_memory deleteRange [0,count _memory - floor VCM_DANGERMAX]};
_group setVariable ["VCM_DangerMemory",_memory,true];
true
