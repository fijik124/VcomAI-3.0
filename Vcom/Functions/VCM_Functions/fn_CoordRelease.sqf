params ["_group",["_key",[]]];
if (!local _group) exitWith {};
private _mission = _group getVariable ["VCM_CoordMission",[]];
if (_mission isEqualTo [] || {_key isNotEqualTo [] && {!((_mission select 0) isEqualTo _key)}}) exitWith {};
_key = _mission select 0;
private _partner = _group getVariable ["VCM_ArmorPartner",[]];
if (_partner isNotEqualTo [] && {(_partner select 1) isEqualTo _key}) then {
    private _vehicle = vehicle leader _group;
    if (local _vehicle && {((_vehicle getVariable ["VCM_InfantryPartner",[]]) param [1,[]]) isEqualTo _key}) then {
        _vehicle setVariable ["VCM_InfantryPartner",nil,true];
    };
    _group setVariable ["VCM_ArmorPartner",nil,true];
};
_group setVariable ["VCM_CoordMission",nil,true];
