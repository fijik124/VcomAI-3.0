/* Profiles change tactical preferences, never skills, supplies or mission engagement rules. */
params ["_group"];
if (!VCM_DOCTRINES) exitWith {"default"};
private _profile = _group getVariable ["VCM_Doctrine","auto"];
if (_profile == "auto") then {_profile = if (VCM_AUTODOCTRINE) then {_group getVariable ["VCM_AutoRole","default"]} else {"default"}};
if !(_profile in ["default","recon","assault","defend","convoy"]) exitWith {"default"};
if ((_profile == "recon" && {!VCM_RECON}) || {_profile == "defend" && {!VCM_DEFENSE}}) exitWith {"default"};
_profile
