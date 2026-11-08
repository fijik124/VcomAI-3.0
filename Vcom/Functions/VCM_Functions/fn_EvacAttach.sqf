params ["_group","_key","_rescuer","_patient"];
if (!VCM_CASEVAC || {!VCM_MEDICALACTIVE && {!VCM_ACECASEVAC}} ||
    {!local _rescuer} || {!local _patient} || {!alive _patient} ||
    {[_patient] call VCM_fnc_HumanControlled} || {[_rescuer] call VCM_fnc_HumanControlled} ||
    {group _patient != _group} || {_rescuer distance _patient > 3} || {!isNull attachedTo _patient} ||
    {!isNull objectParent _patient} ||
    {!(lifeState _patient == "INCAPACITATED" || {VCM_ACECASEVAC && {_patient getVariable ["ACE_isUnconscious",false]}})}) exitWith {false};
private _speed = getForcedSpeed _rescuer;
_group setVariable ["VCM_Evacuation",[_key,_rescuer,_patient,_speed],true];
_patient setVariable ["VCM_EvacPatient",[_group,_key,_rescuer,_speed],true];
_rescuer setVariable ["VCM_EvacRescuer",[_group,_key,_patient,_speed],true];
_rescuer forceSpeed 1;
_patient attachTo [_rescuer,[0,1,0]];
[_group,"evac-attach",format ["%1 recovering %2",_rescuer,_patient]] call VCM_fnc_DebugTrace;
true
