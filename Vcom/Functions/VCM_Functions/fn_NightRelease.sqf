/* Release the group laser permission before restoring individual observed attachment states. */
params ["_group"];
if (!local _group) exitWith {};
private _laser = _group getVariable ["VCM_NightIRControl",[]];
if (_laser isEqualTo [] && {!(_group getVariable ["VCM_NightOwned",false])}) exitWith {};
if (_laser isNotEqualTo []) then {
    _group enableIRLasers (_laser select 0);
    _group setVariable ["VCM_NightIRControl",nil,true];
};
{[_x,_laser isNotEqualTo []] call VCM_fnc_RestoreNight} forEach units _group;
_group setVariable ["VCM_NightOwned",false,true];
