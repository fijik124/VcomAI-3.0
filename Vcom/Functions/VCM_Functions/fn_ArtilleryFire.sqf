/* Execute one server-authorized fire mission where the gun is currently local. */
if (!(isServer && {!isRemoteExecuted}) && {!isRemoteExecuted || {remoteExecutedOwner != 2}}) exitWith {false};
params ["_vehicle","_impact","_side","_rounds"];
if (!Vcm_ActivateAI || {!VCM_ARTYENABLE} || {!local _vehicle} || {!alive _vehicle} || {!alive gunner _vehicle} ||
    {isPlayer gunner _vehicle} || {!([side _vehicle,_side] call BIS_fnc_sideIsFriendly)} ||
    {!(side _vehicle in VCM_ARTYSIDES)} || {!(side _vehicle in VCM_SIDEENABLED)} ||
    {group gunner _vehicle getVariable ["Vcm_Disable",false]} ||
    {group gunner _vehicle getVariable ["VCM_NOARTY",false]} ||
    {!(unitCombatMode gunner _vehicle in ["YELLOW","RED"])} ||
    {time < (_vehicle getVariable ["VCM_ArtyNext",-1])}) exitWith {false};
private _ammunition = (getArtilleryAmmo [_vehicle]) select {
    ([_x] call VCM_fnc_ArtilleryAmmo) == "HE" && {_impact inRangeOfArtillery [[_vehicle],_x]}
};
if (_ammunition isEqualTo []) exitWith {false};
private _magazine = _ammunition select 0;
private _ammo = configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
private _radius = 100 max (getNumber (_ammo >> "indirectHitRange") * 3);
if (!(_impact inRangeOfArtillery [[_vehicle],_magazine]) || {!([_side,_impact,_radius] call VCM_fnc_ArtillerySafe)}) exitWith {false};
// A public deadline must use mission time, not each process's launch-relative clock.
_vehicle setVariable ["VCM_ArtyNext",time + (VCM_ARTYDELAY max 10),true];
_vehicle setVariable ["VCM_LastFireMission",[_impact,_magazine,(_rounds max 1) min 3,clientOwner],true];
_vehicle doArtilleryFire [_impact,_magazine,(_rounds max 1) min 3];
true
