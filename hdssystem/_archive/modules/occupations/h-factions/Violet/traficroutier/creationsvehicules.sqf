/*
Description : fonction permettant la création de véhicule civils sur routes

[<entier>,<tableau>,<entier>]

0 : identifiant pour reconnaitre un trigger
1 : Le nombre de véhicules à Créer
2 : la position centrale
3 : le rayon de création se basant sur la position centrale

exemple : [1,3,getpos objet,1000] execvm "h-occupations\h-factions\violet\traficroutier\créationsvehicules.sqf";
ou
[1,3,getpos objet,1000] spawn fnc_creationsvehicules;
*/

params ["_nbvehicule","_position","_rayon"];
_listeobjets = [];

for "_nb" from 1 to _nbvehicule do {
  _listeitineraires = (_position nearRoads _rayon);
  _posvehicule = getpos (selectRandom _listeitineraires);

  _levehicule = [_posvehicule,0,(SelectRandom HListeVehiculeCivils),civilian] call bis_fnc_spawnvehicle;
  createVehicleCrew (_levehicule select 0);

  _levehicule select 2 setSpeedMode "limited";
  _levehicule select 2 setCombatMode "green";
  _levehicule select 2 setBehaviour "careless";

  _itineraire_arriver_aller = _levehicule select 2 addWaypoint [getpos (selectRandom _listeitineraires),0];
  while {Waypointposition _itineraire_arriver_aller isequalto [0,0,0]} do {
    _itineraire_arriver_aller = _levehicule select 2 addWaypoint [getpos (selectRandom _listeitineraires),0];
    _itineraire_arriver_aller setWaypointType "move";
  };

  _itineraire_depart =_levehicule select 2 addWaypoint [getpos (selectRandom _listeitineraires),0];
  while {Waypointposition _itineraire_depart isequalto [0,0,0]} do {
  _itineraire_depart =_levehicule select 2 addWaypoint [getpos (selectRandom _listeitineraires),0];
  _itineraire_depart setWaypointType "cycle";
  };

  //Ajout des noms de variable des vehicule et leurs équipages dans un tableau
  _listeobjets append [(_levehicule select 0)];
  _listeobjets append (_levehicule select 1);
  };

  waituntil {((getpos leader group player) distance _position) > (_rayon + 250)};
  {deleteVehicle _x} foreach _listeobjets;
