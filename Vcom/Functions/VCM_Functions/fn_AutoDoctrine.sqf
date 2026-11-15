/* Autonomous roles use squad condition, carried supplies and remembered contacts; Zeus orders are optional overrides. */
params ["_group"];
if (!local _group || {(_group getVariable ["VCM_Doctrine","auto"]) != "auto"}) exitWith {};
private _blocked = !VCM_AUTODOCTRINE || {!VCM_DOCTRINES} ||
    {_group getVariable ["VCM_NOAUTOTACTICS",false]} || {_group getVariable ["VCM_NOFLANK",false]} ||
    {(waypoints _group) findIf {(_x select 1) > 0} >= 0};
if (_blocked) exitWith {
    if ((_group getVariable ["VCM_AutoRole","default"]) != "default") then {_group setVariable ["VCM_AutoRole","default",true]};
};
if (time < (_group getVariable ["VCM_AutoRoleAfter",-1])) exitWith {};
private _alive = (units _group) select {alive _x && {!([_x] call VCM_fnc_HumanControlled)}};
private _strength = count _alive;
if (_strength == 0) exitWith {};
private _pressure = 0;
private _supplied = 0;
private _vehicles = [];
{
    _pressure = _pressure + getSuppression _x;
    if (primaryWeapon _x != "" && {_x ammo primaryWeapon _x > 5}) then {_supplied = _supplied + 1};
    private _vehicle = vehicle _x;
    if (_vehicle isKindOf "LandVehicle" && {_x == driver _vehicle}) then {_vehicles pushBackUnique _vehicle};
} forEach _alive;
_pressure = _pressure / _strength;
private _contacts = ([leader _group] call VCM_fnc_KnownContacts) select {
    !isNull (_x select 4) && {alive (_x select 4)} && {[side _group,_x select 2] call BIS_fnc_sideIsEnemy} &&
    {leader _group distance2D (_x select 0) <= 500}
};
private _distance = 1e9;
{_distance = _distance min (leader _group distance2D (_x select 0))} forEach _contacts;
private _peak = (_group getVariable ["VCM_PeakStrength",_strength]) max _strength;
private _role = "default";
private _reason = "Balanced squad retains normal tactical selection";
if (count _vehicles >= 2 && {VCM_CONVOY}) then {
    _role = "convoy"; _reason = "Multiple squad vehicles should retain their route and spacing";
} else {
    if (VCM_RECON && {_strength <= 3} && {_distance > 80}) then {
        _role = "recon"; _reason = "Small element observes and reports instead of making an unsupported assault";
    } else {
        if (VCM_DEFENSE && {_contacts isNotEqualTo []} &&
            {_pressure >= 0.35 || {_strength / _peak <= 0.75} || {count _contacts >= ((_strength / 2) max 3)}}) then {
            _role = "defend"; _reason = "Known pressure or squad losses favor covered defensive positions";
        } else {
            if (_strength >= 6 && {_distance >= 80} && {_distance <= 400} && {_pressure < 0.2} && {_supplied / _strength >= 0.7}) then {
                _role = "assault"; _reason = "A supplied, low-pressure squad can conduct a coordinated assault";
            };
        };
    };
};
private _previous = _group getVariable ["VCM_AutoRole","default"];
if (_role != _previous) then {
    _group setVariable ["VCM_AutoRole",_role,true];
    _group setVariable ["VCM_DefenseAnchor",nil,true];
    [_group,"automatic doctrine",_reason] call VCM_fnc_DebugDecision;
};
_group setVariable ["VCM_AutoRoleAfter",time + 20];
