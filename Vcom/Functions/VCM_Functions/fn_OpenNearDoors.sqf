/* Open only nearby, configured vanilla-style doors. Mission locks remain authoritative. */
params ["_unit","_building"];
if (isNull _building || {!local _unit} || {[_unit] call VCM_fnc_HumanControlled}) exitWith {};
{
    _x params ["_index","_source","_position"];
    if (_unit distance _position < 4 &&
        {(_building getVariable [format ["bis_disabled_Door_%1",_index],0]) in [0,false]}) then {
        if (toLower _source find "_sound_" >= 0) then {[_building,_index,1] call BIS_fnc_Door} else {_building animateSource [_source,1]};
    };
} forEach ([_building] call VCM_fnc_CQBDoors);
