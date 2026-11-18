/* Only validated server gunfire reports may start a reaction on another AI owner. */
params [["_shooter",objNull,[objNull]]];
if (remoteExecutedOwner != 2) exitWith {};
if (!Vcm_ActivateAI || {!VCM_CIVILIANS} || {isNull _shooter} || {!alive _shooter}) exitWith {};
private _radius = VCM_CIVILIANRANGE;
private _muzzle = (_shooter weaponAccessories currentWeapon _shooter) param [0,""];
if (_muzzle != "" && {getNumber (configFile >> "CfgWeapons" >> _muzzle >> "ItemInfo" >> "AmmoCoef" >> "audibleFire") < 1}) then {
    _radius = _radius * 0.25;
};
private _near = _shooter nearEntities ["CAManBase",_radius];
{
    if ([_x] call VCM_fnc_CivilianEligible) then {
        _x setVariable ["VCM_CivilianThreat",[getPosATL _shooter,time + VCM_CIVILIANPANIC],true];
        [_x] call VCM_fnc_CivilianTick;
    };
} forEach _near;
