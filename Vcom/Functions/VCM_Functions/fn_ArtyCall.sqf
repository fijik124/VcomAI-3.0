/* Author: Genesis. Fire only supported ammunition at a known hostile contact. */
params ["_callGroup", "_enemyGroup", ["_knowledge", 0]];
if (!VCM_ARTYENABLE || {!([_callGroup] call VCM_fnc_GroupEnabled)}) exitWith {};
private _leader = leader _callGroup;
private _enemy = _leader call VCM_fnc_ClstEmy;
if (isNull _enemy || {group _enemy != _enemyGroup}) exitWith {};
private _target = [_leader, _enemy] call VCM_fnc_ContactPosition;
if (_target isEqualTo []) exitWith {};
private _side = side _callGroup;
private _quality = ((_callGroup knowsAbout _enemy) max 0) min 4;
private _dispersion = 25 + (4 - _quality) * 35;
private _rounds = 1 + floor (_quality / 2);
VCM_ARTYLST = VCM_ARTYLST select {alive _x && {count crew _x > 0}};
{
    private _vehicle = _x;
    if (local _vehicle && {alive gunner _vehicle} && {!isPlayer gunner _vehicle} &&
        {[side _vehicle, _side] call BIS_fnc_sideIsFriendly} && {side _vehicle in VCM_ARTYSIDES} &&
        {!(group gunner _vehicle getVariable ["Vcm_Disable", false])}) then {
        private _supported = getArtilleryAmmo [_vehicle];
        private _ammunition = _supported select {([_x] call VCM_fnc_ArtilleryAmmo) == "HE"};
        if (count _ammunition > 0) then {
            private _magazine = _ammunition select 0;
            private _impact = _target getPos [random _dispersion, random 360];
            private _ammo = configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
            private _radius = 100 max (getNumber (_ammo >> "indirectHitRange") * 3);
            if (_impact inRangeOfArtillery [[_vehicle], _magazine] && {[_side, _impact, _radius] call VCM_fnc_ArtillerySafe}) then {
                _vehicle doArtilleryFire [_impact, _magazine, _rounds];
            };
        };
    };
} forEach VCM_ARTYLST;
