/* Retain the final search report; release only this session's live ownership tag. */
params ["_group","_key",["_reason","cancelled"]];
if (!local _group) exitWith {};
private _session = _group getVariable ["VCM_CQBSession",[]];
if (_session isEqualTo [] || {!((_session select 0) isEqualTo _key)}) exitWith {};
private _progress = _group getVariable ["VCM_CQBProgress",[]];
// Group and unit locality can change on different engine updates during a handoff.
private _participants = (_group getVariable ["VCM_Task",[]]) param [2,[]];
private _handoff = _reason == "owner-changed" || {groupOwner _group != clientOwner} ||
    {_participants findIf {!isNull _x && {!local _x}} >= 0};
if (_handoff) then {_reason = "owner-changed"};
if (_progress isNotEqualTo [] && {(_progress select 0) isEqualTo _key} &&
    {(_progress select 2) == "searching" || {_handoff && {(_progress select 2) in ["partial","cancelled"]}}}) then {
    _progress set [2,if (_reason == "owner-changed") then {"owner-changed"} else {"cancelled"}];
    _progress set [10,_reason];
    if (_reason == "timeout" && {_progress select 3 < 0}) then {
        _progress set [2,"partial"]; _progress set [10,"staging-timeout"];
    };
    _group setVariable ["VCM_CQBProgress",_progress,true];
};
_group setVariable ["VCM_CQBSession",nil,true];
