/* Revalidate point identity and command revision while native movers run on the current owner. */
params ["_group","_key","_kind"];
if (_kind == "fallback" && {!VCM_TACTICALRETREAT}) exitWith {false};
private _context = _group getVariable ["VCM_ObjectiveContext",[]];
if (_context isEqualTo [] || {!((_context select 0) isEqualTo _key)} ||
    {_group getVariable ["VCM_CommandRevision",0] != (_context select 3)}) exitWith {false};
if (_kind == "recon" && {time - (_group getVariable ["VCM_LastIncoming",-100]) < 15}) exitWith {false};
if (_kind == "recon" && {(units _group) findIf {getSuppression _x >= 0.35} >= 0}) exitWith {false};
private _order = _context select 1;
if (_order select 0 == "doctrine") exitWith {
    ([_group] call VCM_fnc_Doctrine) == _kind
};
if (!VCM_COMMANDPOINTS) exitWith {false};
private _live = _group getVariable [if (_kind == "fallback") then {"VCM_FallbackPoint"} else {"VCM_Objective"},[]];
_live isEqualTo _order
