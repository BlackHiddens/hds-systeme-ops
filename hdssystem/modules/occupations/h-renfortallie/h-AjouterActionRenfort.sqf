params ["_UnObjet","_Message"];
_Message = format ["<t color='#353531'>H</t>|%1",_Message];
_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa";

[_UnObjet,                                 //L'objet sur lequel l'action est attachée
_Message,                                 //Titre de l'action
_Icone,                                     //L'icone qui est affiché à l'écran
_Icone,                                     //L'icone de progression
"_this distance _target < 7",                         //Contion pour que l'action soit affiché
"_this distance _target < 7",                         //Condition pour que l'action progresse
{playSound "rhs_usa_land_rc_25"},                                         //Le code exécuté quand l'action commence
{},     //Le code exécuté quand l'action est entrain de progressé
{[_caller] ExecVM "h-missions\h-modules\h-occupations\h-renfortallie\h-RenfortAllie.sqf"},                                         //Le code exécuté dans l'action est terminée
{},                                         //Le code exécuté si l'action est intérrompu
[],                                         //Arguments passed to the scripts as _this select 3
5,                                          //Durée de l'action
0,                                          //Prioritée
false,                                       //Supprimer quand l'action est terminé ?
false                                       //Montrer dans l'attat d'inconscience ?
] remoteExec ["BIS_fnc_holdActionAdd",0,_UnObjet];   //-2 : Tous le monde sauf le serveur
