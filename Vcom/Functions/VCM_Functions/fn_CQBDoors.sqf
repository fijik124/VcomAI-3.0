/* Fixed door metadata, never animation statements or remotely supplied code. */
params ["_building"];
private _doors = [];
{
    private _source = configName _x;
    private _parts = (toLower _source) splitString "_";
    if (count _parts >= 3 && {_parts select 0 == "door"} && {_parts select (count _parts - 1) == "source"}) then {
        private _number = parseNumber (_parts select 1);
        private _memory = format ["Door_%1_trigger",_number];
        private _position = _building selectionPosition [_memory,"Memory"];
        if (_number > 0 && {_position isNotEqualTo [0,0,0]} && {_doors findIf {_x select 0 == _number} < 0}) then {
            private _plain = format ["Door_%1_source",_number];
            private _sound = format ["Door_%1_sound_source",_number];
            _source = if (isClass (configOf _building >> "AnimationSources" >> _sound)) then {_sound} else {_plain};
            if (isClass (configOf _building >> "AnimationSources" >> _source)) then {
                _doors pushBack [_number,_source,_building modelToWorld _position];
            };
        };
    };
} forEach ("true" configClasses (configOf _building >> "AnimationSources"));
_doors
