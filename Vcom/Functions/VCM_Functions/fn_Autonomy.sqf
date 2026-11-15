/* Explicit observation/defense orders and cautious doctrines block competing offensive planners. */
params ["_group"];
private _profile = [_group] call VCM_fnc_Doctrine;
private _objective = _group getVariable ["VCM_Objective",[]];
!(_profile in ["recon","defend","convoy"]) &&
{!VCM_COMMANDPOINTS || {_objective isEqualTo []} ||
    {(_objective select 1 == "recon" && {!VCM_RECON}) || {(_objective select 1 == "defend" && {!VCM_DEFENSE})}}}
