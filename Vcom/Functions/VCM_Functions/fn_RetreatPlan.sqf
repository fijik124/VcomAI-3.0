/* Decide from local squad condition and a remembered hostile contact, without inspecting unseen enemies. */
params ["_group"];
if (!VCM_TACTICALRETREAT || {!([_group] call VCM_fnc_GroupEnabled)} ||
    {diag_tickTime < (_group getVariable ["VCM_RetreatAfter",-1])} || {!isNull objectParent leader _group}) exitWith {[]};
private _alive = (units _group) select {alive _x};
private _peak = (_group getVariable ["VCM_PeakStrength",count _alive]) max count _alive;
if (_peak < 4 || {count _alive < 2}) exitWith {[]};
private _enemy = leader _group call VCM_fnc_ClstEmy;
private _contact = [leader _group,_enemy] call VCM_fnc_ContactPosition;
if (_contact isEqualTo [] || {leader _group distance2D _contact > 500}) exitWith {[]};
private _pressure = 0;
private _armed = 0;
private _supplied = 0;
{
    _pressure = _pressure + getSuppression _x;
    if (primaryWeapon _x != "") then {
        _armed = _armed + 1;
        private _compatible = compatibleMagazines primaryWeapon _x;
        private _rounds = 0;
        {if (_x select 0 in _compatible) then {_rounds = _rounds + (_x select 1)}} forEach magazinesAmmoFull _x;
        if (_rounds > 10) then {_supplied = _supplied + 1};
    };
} forEach _alive;
_pressure = _pressure / count _alive;
private _casualties = 1 - count _alive / _peak;
private _reason = "";
if (_casualties >= VCM_RETREATLOSS) then {_reason = "casualties"};
if (_armed > 0 && {_supplied / _armed < 0.34}) then {_reason = "ammunition"};
if (_pressure >= VCM_RETREATSUPPRESSION) then {_reason = "suppression"};
if (_reason == "") exitWith {[]};
[_enemy,_contact,_reason]
