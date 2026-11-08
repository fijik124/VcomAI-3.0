/* Recover AI casualties only; ACE participation is opt-in and never changes medical state. */
params ["_group"];
if (!VCM_CASEVAC || {!VCM_MEDICALACTIVE && {!VCM_ACECASEVAC}} ||
    {!([_group] call VCM_fnc_TacticalReady)} || {diag_tickTime < (_group getVariable ["VCM_EvacAfter",-1])}) exitWith {[]};
private _patients = (units _group) select {
    local _x && {alive _x} && {!([_x] call VCM_fnc_HumanControlled)} && {isNull objectParent _x} &&
    {isNull attachedTo _x} && {!(_x getVariable ["VCM_PatientBusy",false])} &&
    {lifeState _x == "INCAPACITATED" || {VCM_ACECASEVAC && {_x getVariable ["ACE_isUnconscious",false]}}}
};
private _rescuers = ([_group] call VCM_fnc_TacticalUnits) select {!(_x getUnitTrait "Medic")};
if (_patients isEqualTo [] || {_rescuers isEqualTo []}) exitWith {[]};
private _enemy = leader _group call VCM_fnc_ClstEmy;
private _contact = [leader _group,_enemy] call VCM_fnc_ContactPosition;
if (_contact isEqualTo []) exitWith {[]};
private _patient = _patients select 0;
_rescuers = [_rescuers,[],{_x distance _patient},"ASCEND"] call BIS_fnc_sortBy;
private _rescuer = _rescuers select 0;
if (_rescuer distance _patient > VCM_EVACRANGE || {_patient distance2D _contact < 50}) exitWith {[]};
private _best = [];
private _score = [_rescuer,getPosATL _patient,_contact] call VCM_fnc_CoverProtection;
{
    private _radius = _x;
    {
        private _point = (_patient getPos [_radius,(_patient getDir _contact) + 180 + _x]) findEmptyPosition [0,2,typeOf _rescuer];
        if (_point isNotEqualTo [] && {!surfaceIsWater _point} && {_patient distance2D _point <= VCM_EVACDISTANCE} &&
            {(surfaceNormal _point select 2) > 0.8}) then {
            private _cover = [_rescuer,_point,_contact] call VCM_fnc_CoverProtection;
            if (_cover > _score) then {_score = _cover; _best = _point};
        };
    } forEach [0,-45,45,-90,90];
} forEach [VCM_EVACDISTANCE * 0.5,VCM_EVACDISTANCE];
if (_best isEqualTo []) exitWith {[]};
[_rescuer,_patient,_best,_enemy,_contact]
