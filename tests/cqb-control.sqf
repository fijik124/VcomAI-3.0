/* Locked-door, mission-order and feature-switch acceptance use fresh native actors. */
private _savedRooms = VCM_CQBROOMS;
{
    private _case = _x;
    private _group = createGroup [west,true];
    _group setVariable ["VCM_Skilldisable",true];
    _group setVariable ["VCM_NOAUTOTACTICS",true];
    private _actors = [];
    for "_i" from 0 to 3 do {
        private _actor = _group createUnit ["B_Soldier_F",[10200,11000 + _i * 5,0],[],0,"NONE"];
        _actor allowDamage false; _actors pushBack _actor;
    };
    _group setCombatMode "GREEN";
    _group setBehaviour "COMBAT";
    _group call VCM_fnc_SquadExc;
    private _building = createVehicle ["Land_i_House_Small_01_V1_F",[10225,11000,0],[],0,"CAN_COLLIDE"];
    private _opfor = createGroup [east,true];
    _opfor setVariable ["Vcm_Disable",true];
    private _enemy = _opfor createUnit ["O_Soldier_F",(_building buildingPos -1) select 0,[],0,"NONE"];
    _enemy disableAI "ALL"; _enemy allowDamage false;
    _group reveal [_enemy,4];
    private _layout = [_building] call VCM_fnc_CQBLayout;
    private _doors = _layout select 4;
    if (_case == "locks") then {{_building setVariable [format ["bis_disabled_Door_%1",_x select 0],1,true]} forEach _doors};
    if (_case == "limit") then {VCM_CQBROOMS = 2};
    private _readyUntil = diag_tickTime + 6;
    waitUntil {sleep 0.1; count ([_group] call VCM_fnc_TacticalUnits) >= 4 &&
        {([leader _group,_enemy] call VCM_fnc_ContactPosition) isNotEqualTo []} || {diag_tickTime >= _readyUntil}};
    private _job = [_group,_enemy] spawn VCM_fnc_ClearBuilding;
    private _until = diag_tickTime + 35;
    if (_case in ["order","disable"]) then {
        waitUntil {sleep 0.2; ((_group getVariable ["VCM_CQBProgress",[]]) param [3,-1]) >= 0 || {scriptDone _job} || {diag_tickTime > _until}};
        [!scriptDone _job && {((_group getVariable ["VCM_CQBProgress",[]]) param [3,-1]) >= 0},_case + ": room search is active before cancellation"] call _assert;
        if (_case == "order") then {
            private _order = _group addWaypoint [[10300,11100,0],0]; _order setWaypointName "CQB_AUTHORED_ORDER";
        } else {VCM_FULLCLEAR = false};
        _until = diag_tickTime + 3;
    } else {_until = diag_tickTime + 100};
    waitUntil {sleep 0.2; scriptDone _job || {diag_tickTime > _until}};
    private _progress = _group getVariable ["VCM_CQBProgress",[]];
    diag_log format ["VCM_CQB_CONTROL: case=%1 progress=%2",_case,_progress];
    [scriptDone _job && {_progress param [2,""] != "searched"},_case + ": interrupted or limited search never reports full coverage"] call _assert;
    [_group getVariable ["VCM_CQBSession",[]] isEqualTo [] && {_group getVariable ["VCM_Task",[]] isEqualTo []},_case + ": search releases its live session and task"] call _assert;
    [_actors findIf {_x getVariable ["VCM_TaskKey",[]] isNotEqualTo [] || {!(_x checkAIFeature "PATH")}} < 0,_case + ": per-unit reservations clear and pathfinding stays enabled"] call _assert;
    if (_case == "locks") then {
        [_doors findIf {_building animationSourcePhase (_x select 1) > 0.01} < 0,"room search does not open mission-locked doors"] call _assert;
        [(_progress param [6,[]]) isNotEqualTo [] || {(_progress param [10,""]) == "staging-timeout" && {_progress select 3 < 0}},
            "locked-door search reports blocked rooms or an explicit failure to reach exterior staging"] call _assert;
    };
    if (_case == "limit") then {[_progress param [10,""] == "room-limit","room limit produces an explicit partial-search reason"] call _assert};
    if (_case == "order") then {[(waypoints _group) findIf {waypointName _x == "CQB_AUTHORED_ORDER"} >= 0,"room-search cancellation preserves the authored mission order"] call _assert};
    VCM_FULLCLEAR = true;
    VCM_CQBROOMS = _savedRooms;
    _group setVariable ["Vcm_Disable",true];
    sleep 0.5;
    {deleteVehicle _x} forEach (_actors + [_building,_enemy]);
    deleteGroup _group; deleteGroup _opfor;
} forEach ["locks","order","disable","limit"];
