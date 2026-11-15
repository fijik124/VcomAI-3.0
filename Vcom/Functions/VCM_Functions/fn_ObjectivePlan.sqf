/* Build observation, defense or fallback positions without replacing authored waypoints. */
params ["_group",["_requested",""]];
if (!([_group] call VCM_fnc_TacticalReady) ||
    {_requested != "fallback" && {diag_tickTime < (_group getVariable ["VCM_ObjectiveAfter",-1])}}) exitWith {[]};
private _profile = [_group] call VCM_fnc_Doctrine;
private _order = if (_requested == "fallback") then {
    if (VCM_COMMANDPOINTS) then {_group getVariable ["VCM_FallbackPoint",[]]} else {[]}
} else {if (VCM_COMMANDPOINTS) then {_group getVariable ["VCM_Objective",[]]} else {[]}};
if (_order isEqualTo [] && {_requested != "fallback"} && {_profile in ["recon","defend"]}) then {
    private _anchor = _group getVariable ["VCM_DefenseAnchor",[]];
    if (_anchor isEqualTo []) then {
        _anchor = [getPosATL leader _group,getDir leader _group];
        _group setVariable ["VCM_DefenseAnchor",_anchor,true];
    };
    _order = ["doctrine",_profile,_anchor select 0,_anchor select 1,VCM_POINTRADIUS,_group getVariable ["VCM_CommandRevision",0]];
};
if (_order isEqualTo []) exitWith {[]};
_order params ["_id","_kind","_center","_bearing","_radius","_revision"];
if ((_kind == "recon" && {!VCM_RECON}) || {_kind in ["defend","fallback"] && {!VCM_DEFENSE}} ||
    {leader _group distance2D _center > VCM_POINTMAXDIST}) exitWith {[]};
if (_kind == "recon" && {time - (_group getVariable ["VCM_LastIncoming",-100]) < 15}) exitWith {[]};
private _enemy = leader _group call VCM_fnc_ClstEmy;
private _contact = [leader _group,_enemy] call VCM_fnc_ContactPosition;
private _watch = if (_contact isEqualTo []) then {_center getPos [200,_bearing]} else {_contact};
if (_id == "doctrine" && {_kind == "recon"} && {_contact isNotEqualTo []}) then {
    private _distance = leader _group distance2D _contact;
    if (_distance > VCM_RECONSTANDOFF + 15) then {
        _center = leader _group getPos [(_distance - VCM_RECONSTANDOFF) min 40,leader _group getDir _contact];
    };
};
private _units = ([_group] call VCM_fnc_TacticalUnits) select {!(_x getUnitTrait "Medic")};
_units = _units select [0,8];
if (count _units < 2) exitWith {[]};
private _reserved = [];
private _positions = [];
{
    private _point = [_x,_center,_watch,_radius,_reserved] call VCM_fnc_DefensivePosition;
    _positions pushBack _point;
    if (_point isNotEqualTo []) then {_reserved pushBack _point};
} forEach _units;
if (_positions findIf {_x isEqualTo []} >= 0) exitWith {[]};
[_order,_units,_positions,_enemy,_watch]
