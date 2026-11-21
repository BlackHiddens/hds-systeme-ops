params ["_unobjet","_message"];

_message = format ["<t color='#353531'>%2</t>|%1",_message,hdsversion];
_icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa";

[_unobjet,    //L'objet sur lequel l'action est attachée
_message,     //Titre de l'action
_icone,       //L'icone qui est affiché à l'écran
_icone,       //L'icone de progression
"_this distance _target < 0.1", //Contion pour que l'action soit affiché
"_this distance _target < 0.1", //Condition pour que l'action progresse
{},//Le code exécuté quand l'action commence
{},//Le code exécuté quand l'action est entrain de progressé
{
  createVehicleCrew vehicle (_arguments select 0);
  crew vehicle (_arguments select 0) join group (_arguments select 0);
  sleep 2;
  {_x moveincargo vehicle (_arguments select 0)} foreach units group (_arguments select 0);
  if(hdssysteme)then{[format["%1: Equipage prêt",hdsversion]] remoteexeccall ["systemChat",(_arguments select 0)]};
},                                          //Le code exécuté dans l'action est terminée
{},                                         //Le code exécuté si l'action est intérrompu
[_unobjet],                                         //Arguments passed to the scripts as _this select 3
0.5,                                          //Durée de l'action
0,                                          //Prioritée
false,                                      //Supprimer quand l'action est terminé ?
false                                       //Montrer dans l'attat d'inconscience ?
] remoteExec ["BIS_fnc_holdActionAdd",0,_unobjet];//-2 : T
