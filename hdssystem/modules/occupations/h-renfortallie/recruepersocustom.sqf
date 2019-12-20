if(isDedicated)ExitWith{};
params ["_nombre"];
_nombre = parseNumber (_this select 0);
_LeGroupeOperation = [([getpos player,50,100,1,0,60,0] call BIS_fnc_findSafePos),CampsRenfortAllie,_nombre] call BIS_fnc_spawnGroup;

[player,[missionNamespace,"hdsv70136"]] call BIS_fnc_saveInventory;

{[_x,[missionNamespace,"hdsv70136"]] call BIS_fnc_loadInventory} foreach Units _LeGroupeOperation;

(Units _LeGroupeOperation) join (group player);

[player,[missionNamespace,"hdsv70136"]] call BIS_fnc_deleteInventory;
