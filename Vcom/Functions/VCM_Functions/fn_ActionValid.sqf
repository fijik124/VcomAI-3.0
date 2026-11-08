/* Capture the run token before suspending; old actions cannot resume a new run. */
params ["_unit", "_group", "_run"];
_run isNotEqualTo [] && {alive _unit} && {local _unit} && {!([_unit] call VCM_fnc_HumanControlled)} && {group _unit isEqualTo _group} &&
{[_group] call VCM_fnc_GroupEnabled} && {_run isEqualTo (_group getVariable ["VCM_RunId", []])}
