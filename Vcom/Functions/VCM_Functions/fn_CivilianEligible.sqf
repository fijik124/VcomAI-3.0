/* Civilian reactions are separate from combat-side activation. Mission locks always take priority. */
params ["_unit"];
private _controlled = _unit getVariable ["VCM_CivilianState",[]] isNotEqualTo [];
local _unit && {alive _unit} && {simulationEnabled _unit} &&
{Vcm_ActivateAI} && {VCM_CIVILIANS} && {side group _unit == civilian} &&
{!([_unit] call VCM_fnc_HumanControlled)} && {isNull objectParent _unit} && {isNull attachedTo _unit} &&
{lifeState _unit != "INCAPACITATED"} && {!(_unit getVariable ["ACE_isUnconscious",false])} &&
{!captive _unit} && {!(_unit getVariable ["ace_captives_isHandcuffed",false])} &&
{!(_unit getVariable ["ace_captives_isSurrendering",false])} &&
{!(_unit getVariable ["VCM_NOCIVILIAN",false])} && {!((group _unit) getVariable ["VCM_NOCIVILIAN",false])} &&
{!((group _unit) getVariable ["Vcm_Disable",false])} &&
{primaryWeapon _unit == ""} && {handgunWeapon _unit == ""} && {secondaryWeapon _unit == ""} &&
{_unit checkAIFeature "MOVE"} && {_unit checkAIFeature "ANIM"} &&
{_controlled || {_unit checkAIFeature "PATH" && {getForcedSpeed _unit != 0}}}
