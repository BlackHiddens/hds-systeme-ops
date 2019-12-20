params ["_UnObjet","_Message","_Ordre"];
_Message = format ["<t color='#353531'>H</t>|%1",_Message];
_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa";

[_UnObjet,                                 //L'objet sur lequel l'action est attachée
_Message,                                 //Titre de l'action
_Icone,                                     //L'icone qui est affiché à l'écran
_Icone,                                     //L'icone de progression
"_this distance _target < 7",                         //Contion pour que l'action soit affiché
"_this distance _target < 7",                         //Condition pour que l'action progresse
{},                                         //Le code exécuté quand l'action commence
{},     //Le code exécuté quand l'action est entrain de progressé
{
/* _LeGroupeOperation = [([getpos _caller,50,100,1,0,60,0] call BIS_fnc_findSafePos),CampsRenfortAllie,4] call BIS_fnc_spawnGroup;

[hdssoldat_01,[missionNamespace,"hdssoldat_01"]] call BIS_fnc_saveInventory;
[hdssoldat_02,[missionNamespace,"hdssoldat_02"]] call BIS_fnc_saveInventory;
[hdssoldat_03,[missionNamespace,"hdssoldat_03"]] call BIS_fnc_saveInventory;

{[_x,[missionNamespace,(selectrandom ["hdssoldat_01","hdssoldat_02","hdssoldat_03"])]] call BIS_fnc_loadInventory} foreach Units _LeGroupeOperation;

(Units _LeGroupeOperation) join (group _caller); */
_mafenetre = createDialog "hds_recrutementperso";
},                                         //Le code exécuté dans l'action est terminée
{},                                         //Le code exécuté si l'action est intérrompu
[],                                         //Arguments passed to the scripts as _this select 3
1,                                          //Durée de l'action
_Ordre,                                          //Prioritée
false,                                       //Supprimer quand l'action est terminé ?
false                                       //Montrer dans l'attat d'inconscience ?
] remoteexeccall ["BIS_fnc_holdActionAdd",player,_UnObjet];
//-----------------------------Version IA Personnlisé---------------------------------------------------------------------
