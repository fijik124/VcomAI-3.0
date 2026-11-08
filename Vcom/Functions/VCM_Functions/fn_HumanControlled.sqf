/* Remote-controlled AI remains isPlayer false; native remote control information is local. */
params ["_unit"];
isPlayer _unit || {local _unit && {!isNull remoteControlled _unit} && {isPlayer remoteControlled _unit}}
