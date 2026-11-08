/* Short pulses only through a clear physical/visible lane under the existing engagement rules. */
params ["_units","_position","_enemy"];
private _pulses = 0;
{
    if (local _x && {alive _x} && {!isPlayer _x} && {isNull objectParent _x} &&
        {unitCombatMode _x in ["YELLOW","RED"]} && {!(_x getUnitTrait "Medic")} &&
        {_x != (group _x getVariable ["VCM_ATShooter",objNull])} &&
        {primaryWeapon _x != ""} && {_x ammo primaryWeapon _x > 0} && {getSuppression _x < 0.85} &&
        {[_x,_position,_enemy] call VCM_fnc_FireLaneClear}) then {
        _x doWatch (_position vectorAdd [0,0,1]);
        _x suppressFor 2;
        _pulses = _pulses + 1;
    };
} forEach _units;
_pulses
