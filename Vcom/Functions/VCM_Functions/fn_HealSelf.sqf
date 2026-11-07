/* Author: Genesis. Use the vanilla action; never synthesize a full heal. */
private _unit = _this;
if (!VCM_MEDICALACTIVE || {!local _unit} || {!alive _unit} || {isPlayer _unit} ||
    {lifeState _unit == "INCAPACITATED"} || {!("FirstAidKit" in items _unit)}) exitWith {false};
_unit action ["HealSoldierSelf", _unit];
true
