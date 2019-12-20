/*
  fnc_tactique_groupedecombat

  dépèche un ou plusieurs groupe de combat dans le secteur souhaité,
  ils couront vers l'objectif afin de tenter de l'investir et le sécuriser

  <positions> position central d'attaque
  <string> le nom de la classe du groupe
  <numérique> taille du secteur d'approche
  <side> faction du groupe
  <numerique> nombre de groupe
  <tableau> tableau des véhicules qui peuvent apparaitre
  <numerique> nombre de véhicule qui apparaitrons

  exemple :

  [[4113.82,3864.39,0],
    (configfile >> "CfgGroups" >> "East" >> "LOP_BH" >> "Infantry" >> "LOP_BH_WeaponSquad"),
    250,
    east,
    2,
    hds_liste_vehicule_csat,
    1
    ] spawn fnc_tactique_groupedecombat;

  retourne : true (quand tous les odres ont été donnée)
*/

params ["_centre","_nomclassgroupe","_distanceApproche","_camps","_nombredegroupe","_tableauvehicules","_nombrevehicule"];

//Création de l'infanterie
for "_i" from 1 to (_this select 4) do {

  _groupedecombat = [
  ([(_this select 0),(_this select 2),((_this select 2)+100),1,0,60] call BIS_fnc_findSafePos),
  (_this select 3),
  (_this select 1)
  ] call bis_fnc_spawngroup;
  [(_this select 0),(_this select 2),(_groupedecombat)] spawn fnc_tactique_missionsassaut;
  sleep 0.3;
};

//Création des véhicules
for "_i" from 1 to (_this select 6) do {

    _vehicule = [
      ([(_this select 0),(_this select 2),((_this select 2)+100),1,0,60] call BIS_fnc_findSafePos),
      0,
      (selectrandom (_this select 5)),
      (_this select 3)
      ] call bis_fnc_spawnvehicle;

    [(_this select 0),(_this select 2),(_vehicule select 2)] spawn fnc_tactique_missionassautvehicule;
    sleep 0.3;
};

true
