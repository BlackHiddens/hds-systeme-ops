/*
  fnc_tactique_helicocombat
  dépèche un hélicoptère (Recommandé) ou autre véhicule de combat selon la faction sur zone
  Tous les factions n'ont pas forcement d'hélicoptère de combat

  <positions> position central où le véhicule interviendra
  <string> le nom de la classe de l'hélicoptère
  <numérique> taille du secteur d'intervension
  <side> faction de l'équipage du véhicule choisi

  exemple : [[0,0,0],"O_Heli_Attack_02_dynamicLoadout_F",500,east] spawn fnc_tactique_helicocombat;

  retourne : true (quand tous les odres ont été donnée)
*/

params ["_centre","_vehicule","_taille","_camps"];

//Création du véhicules
_levehicule = [
  ([(_this select 0),((_this select 2)+800),((_this select 2)+1000)] call BIS_fnc_findSafePos),
  0,
  (_this select 1),
  (_this select 3)
] call bis_fnc_spawnvehicle;

//Mission donnée au pilote de l'hélico d'attaque deplacement dans la zone + patrouille
[(_levehicule select 2),(_this select 0)] call BIS_fnc_taskAttack;
waituntil {(_levehicule select 0) inarea [(_this select 0),50,50,0,false,-1]};
[(group driver (_levehicule select 0)),(_this select 0),(_this select 2)] call bis_fnc_taskpatrol;

true
