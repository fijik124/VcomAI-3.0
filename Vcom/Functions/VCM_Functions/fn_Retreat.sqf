params ["_group","_plan"];
if (!([_group] call VCM_fnc_TacticalReady) || {_plan isEqualTo []}) exitWith {false};
_plan params ["_enemy","_contact","_reason"];
private _units = ([_group] call VCM_fnc_TacticalUnits) select [0,12];
if (count _units < 2) exitWith {false};
_units = [_units,[],{private _type = [primaryWeapon _x] call BIS_fnc_itemType; [1,0] select ((_type param [1,""]) == "MachineGun")},"ASCEND"] call BIS_fnc_sortBy;
private _support = _units select [0,(floor (count _units / 2)) min 2];
private _movers = _units - _support;
private _reserved = [];
private _positions = [];
{
    private _destination = [_x,_contact,_reserved] call VCM_fnc_RetreatPosition;
    _positions pushBack _destination;
    if (_destination isNotEqualTo []) then {_reserved pushBack _destination};
} forEach (_movers + _support);
if (_positions findIf {_x isEqualTo []} >= 0) exitWith {false};
_group setVariable ["VCM_RetreatAfter",diag_tickTime + VCM_RETREATCOOLDOWN];
_group setVariable ["VCM_RetreatReason",_reason,true];
[_group,"retreat",[
    [_support,_movers,_positions select [0,count _movers],VCM_RETREATSECONDS,_contact],
    [_movers,_support,_positions select [count _movers],VCM_RETREATSECONDS,_contact]
],_enemy,_contact] call VCM_fnc_RunTactical
