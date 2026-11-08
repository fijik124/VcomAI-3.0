/* Repeatable 128-unit combat load. Run separately with VCOM enabled and disabled. */
Vcm_ActivateAI = VCM_PerfEnabled;
private _groups = [];
private _units = [];
private _features = [];
{
    private _side = _x;
    private _east = _forEachIndex;
    for "_g" from 0 to 7 do {
        private _group = createGroup [_side,true];
        _group setVariable ["VCM_Skilldisable",true];
        for "_n" from 0 to 7 do {
            private _class = [["B_Soldier_F","B_Soldier_AR_F"],["O_Soldier_F","O_Soldier_AR_F"]] select _east select ([0,1] select (_n mod 4 == 0));
            private _unit = _group createUnit [_class,[3000 + _east * 260 + 4 * (_n mod 2),3000 + _g * 45 + _n * 4,0],[],0,"NONE"];
            _unit setSkill 0.5;
            _unit allowDamage false;
            _unit setDir ([90,270] select _east);
            _units pushBack _unit;
            _features pushBack (["PATH","TARGET","AUTOTARGET","AUTOCOMBAT","FSM","FIREWEAPON"] apply {_unit checkAIFeature _x});
        };
        _group setCombatMode "YELLOW";
        _group setBehaviour "COMBAT";
        _groups pushBack _group;
    };
} forEach [west,east];
{
    private _opponent = _groups select ((_forEachIndex + 8) mod 16);
    _x reveal [leader _opponent,4];
} forEach _groups;
sleep 15;
private _started = diag_tickTime;
private _samples = [];
private _maxScripts = 0;
while {diag_tickTime - _started < VCM_PerfSeconds} do {
    _samples pushBack diag_fps;
    _maxScripts = _maxScripts max count diag_activeSQFScripts;
    sleep 1;
};
private _sum = 0;
{_sum = _sum + _x} forEach _samples;
private _ordered = +_samples;
_ordered sort true;
private _mean = _sum / (count _samples max 1);
private _p10 = _ordered select floor (0.1 * count _ordered);
diag_log format ["VCM_PERF_RESULT: enabled=%1; units=%2; meanFPS=%3; p10FPS=%4; maxScripts=%5; activeGroups=%6; elapsed=%7",
    VCM_PerfEnabled,count _units,_mean,_p10,_maxScripts,count VcmAI_ActiveList,diag_tickTime - _started];
[{private _group = _x; {_x isEqualTo _group} count VcmAI_ActiveList > 1} count _groups == 0,
    "performance load has no duplicate group controllers"] call _assert;
Vcm_ActivateAI = false;
sleep 2;
[VcmAI_ActiveList isEqualTo [], "performance load releases every controller on shutdown"] call _assert;
private _restored = true;
{
    private _unit = _x;
    if !(((["PATH","TARGET","AUTOTARGET","AUTOCOMBAT","FSM","FIREWEAPON"] apply {_unit checkAIFeature _x})) isEqualTo (_features select _forEachIndex)) then {_restored = false};
} forEach _units;
[_restored, "performance load restores every owned native AI feature"] call _assert;
{deleteVehicle _x} forEach _units;
{deleteGroup _x} forEach _groups;
