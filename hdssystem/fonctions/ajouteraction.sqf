/*
La fonction sert à créer un addaction Arma3 avec icone et durée d'exécution.
Les parametre attendu son : L'obet concerné & Le message affiché & Le code sqf l'icone qui doit etre affiché & la durée de l'action

LeSujet : nom de l'objet <NomDeLobjet>
LeMessage : Le message de l'action <"Ceci est un message">
QueFaire : Que faire après que l'action soit réussite <"Supprimer"><"NeRienFaire"><VotreCodePersonnaliser>
Icone : L'icon de l'action qui sera affiché en jeux <"Hacker"><"Connecter"><"Rechercher"><"Deconnecter"><"Reanimer">
LaDureeAction : Durée de l'action, le bouton action ne devra pas être relacher pour réussir <999> en secondes
LaDistanceVisible : La distance minimum en mètre ou le joeur doit se tenir pour voir apparaitre l'action <999>
hiddens-scripts|2017
*/
params["_LeSujet","_LeMessage","_Icone","_LaDureeAction","_LaDistanceVisible","_Supprimer","_Codes","_Ordre"];

//Initialisation du parametre Icone. les icone prend le chemin de l'icone selon la réponse de l'utilisateur
switch (_Icone) do {
    case ("Hacker"): {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa"};
    case ("Connecter"): {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa"};
    case ("Rechercher"): {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa"};
    case ("Deconnecter"): {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa"};
    case ("Reanimer"): {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_reviveMedic_ca.paa"};
    case ("atterir"): {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_takeOff1_ca.paa"};
    default {_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa"};
};
//La réponse de l'utilisateur est transformer en code sqf
_LaDistanceVisible = format ["_this distance _target < %1",_LaDistanceVisible];

//La réponse de l'utilisateur est transformer en code SQF, si la réponse n'est pas dans la liste alors il est considéré comme du code.
//Si il y a une erreur alors par défaut l'objet est reste en place.

[_LeSujet,                                  //L'objet sur lequel l'action est attachée
_LeMessage,                                 //Titre de l'action
_Icone,                                     //L'icone qui est affiché à l'écran
_Icone,                                     //L'icone de progression
_LaDistanceVisible,                         //Contion pour que l'action soit affiché
_LaDistanceVisible,                         //Condition pour que l'action progresse
{},                                         //Le code exécuté quand l'action commence
{},//Le code exécuté quand l'action est entrain de progressé
{call compile (_arguments select 0)},       //Le code exécuté dans l'action est terminée
{},                                         //Le code exécuté si l'action est intérrompu
[_Codes],                                     //Arguments passed to the scripts as _this select 3
_LaDureeAction,                               //Durée de l'action
_Ordre,                                      //Prioritée
_Supprimer,                                 //Supprimer quand l'action est terminé ?
false                                       //Montrer dans l'etat d'inconscience ?
] call BIS_fnc_holdActionAdd;
