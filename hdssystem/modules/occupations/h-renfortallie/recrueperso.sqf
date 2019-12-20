/*
Descriptions : Génére des troupes d'ia bleufor qui regrouperons avec le joueur appelant.
_nombre : nombre de soldat créé (Entier)
_location (facultatif) : position où les soldats devrons apparaitre

exemple : [5] execvm 'h-occupations\h-renfortallie\recrueperso.sqf'; Génére 5 ia autour du joueur
exemple : [5,[0,0,0]] execvm 'h-occupations\h-renfortallie\recrueperso.sqf'; génére 5 ia autour de la position fournie
*/
if(isDedicated)ExitWith{};
params ["_TypeEquipe","_location","_camouflage"];


if ((_this select 1) isEqualTo true) then {

_LeGroupeOperation = [([(getpos player),10,30,1,0,60,0] call BIS_fnc_findSafePos),CampsRenfortAllie,4] call BIS_fnc_spawnGroup;
[(_this select 0),(_this select 2),_LeGroupeOperation] remoteExecCall ["fnc_rosequipes",player];
sleep 3;
(Units _LeGroupeOperation) join (group player);

} else {
    _LeGroupeOperation = [([(getpos player),10,30,1,0,60,0] call BIS_fnc_findSafePos),CampsRenfortAllie,4] call BIS_fnc_spawnGroup;
    [(_this select 0),(_this select 2),_LeGroupeOperation] remoteExecCall ["fnc_rosequipes",player];
    sleep 3;
    (Units _LeGroupeOperation) join (group player);
};
