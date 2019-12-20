/*
Description : Gére les appels des différentes tactiques existantes dans le projet.
Cette fonction est celle à appeler pour  générer aléatoirement une tactique sur zone.

Exemple :
["Nom_marker",800,3] spawn fnc_tactique_init;
Attendra qu'un des joueurs (défini aléatoirement) entre dans la zone, attendre entre 100 et 700 seconde avant de choisir
une tactique. les troupes ennemi devront arriver au alontour des 800 metre en prenant comme centre le position du marqueur.
Le camps choisi est 3 ce qui correspond au FIA. voir module h-occupations

_position = <string> est le nom d'un marqueur
_distanceproche = <integer>
_camps = <integer>

*/
params ["_position","_distanceproche","_camps"];


_Condition = "this";
_QuandActiver = "
if(hdssysteme)then{[format['%1:observations des hostiles - entrée',hdsversion]] remoteexeccall ['systemChat',0]};
";
_Declencheur = createTrigger ["EmptyDetector",(_this select 0)];
_Declencheur setTriggerArea [_distanceproche,_distanceproche, 0,false];
_Declencheur setTriggerActivation ["WEST", "EAST D",false];
_Declencheur setTriggerStatements [_Condition,_QuandActiver,""];

_Declencheur_independant = createTrigger ["EmptyDetector",(_this select 0)];
_Declencheur_independant setTriggerArea [_distanceproche,_distanceproche, 0,false];
_Declencheur_independant setTriggerActivation ["WEST", "GUER D",false];
_Declencheur_independant setTriggerStatements [_Condition,_QuandActiver,""];

waitUntil {triggerActivated _Declencheur or triggerActivated _Declencheur_independant};

//Si l'un des joueurs (Choisi aléatoirement) arrive dans le zone d'opération alors attendre entre 100 et 700 secondes
  _intervalmax = random round intervalmax;
  while{_intervalmax < (intervalmax/5)} do {_intervalmax = random round intervalmax};
  sleep _intervalmax;

  _cibleprincipale = selectrandom allplayers;
  //attendre que les joueurs soit présent sur le serveur
  while {(_cibleprincipale inarea [(_this select 0),(_this select 1),(_this select 1),0,false] isequalto false)} do {
      waitUntil {count allplayers > 0};
      _cibleprincipale = selectrandom allPlayers;
      sleep 5;
  };

  if(hdssysteme)then{[format['%1 : Focalisation sur le personnel %2 et sont groupe',hdstactiqueversion,name _cibleprincipale]] remoteexeccall ['systemChat',0]};

      switch (selectrandom [0,1,2,3]) do {
          //Appliquer la tactique 0 : renfort de troupes transporté par véhicule
          case 0:{
            [(getpos _cibleprincipale),(_this select 1),(_this select 2)] spawn fnc_tactique_renfortterrestre;
          };
          //Appliquer la tactique 1 : génère des troupes aux sol fonçant vers un joueur aléatoirement.
          case 1:{
            [(getpos _cibleprincipale),(selectrandom [1,2]),(selectrandom [0,1,2]),(_this select 1),(_this select 2),false] spawn fnc_tactique_contreattaque;
          };
          //Appliquer la tactique 2 : Génération d'un hélicoptère d'attaque envoyé sur zone
          case 2:{
            [(getpos _cibleprincipale),(_this select 1),(_this select 2)] spawn fnc_tactique_appuihelico;
          };
          case 3:{
          //Appliquer la tactique 3 : Génération de troupe embarqué pour déployement
            [(getpos _cibleprincipale),(_this select 1),(_this select 2)] spawn fnc_tactique_insertion;
          };
          default {
            [(getpos _cibleprincipale),(_this select 1),(_this select 2)] spawn fnc_tactique_insertion;
          };
      };
