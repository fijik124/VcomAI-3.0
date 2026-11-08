/* Open only nearby, configured vanilla-style doors. Mission locks remain authoritative. */
params ["_unit","_building"];
if (isNull _building || {!local _unit} || {[_unit] call VCM_fnc_HumanControlled}) exitWith {};
for "_index" from 1 to 12 do {
    private _source = format ["Door_%1_source",_index];
    private _selection = _building selectionPosition [format ["Door_%1_trigger",_index],"Memory"];
    if (_selection isNotEqualTo [0,0,0] && {_unit distance (_building modelToWorld _selection) < 4} &&
        {isClass (configOf _building >> "AnimationSources" >> _source)} &&
        {_building getVariable [format ["bis_disabled_Door_%1",_index],0] == 0}) then {
        _building animateSource [_source,1];
    };
};
