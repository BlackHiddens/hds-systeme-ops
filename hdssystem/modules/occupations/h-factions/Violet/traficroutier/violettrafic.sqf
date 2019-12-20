/*
Description : Créer un trafic routier autour d'un joueur

[<Objet>,<Entier>,<Entier>]

1 : Joueurs autre objet
2 : Rayon en mètres
3 : Nombre de voiture

exemple : [_objet,200,5] spawn fnc_VioletTrafic;
*/
params ["_rayon","_nbvehicule"];
waituntil{count allplayers > 0};

  //Placement des triggers sur les positions
  {
      _x = locationposition _x;
      //sleep 5;hint format ["[%1,%2,%3] execvm 'h-occupations\h-factions\violet\traficroutier\creationsvehicules.sqf'",_nbvehicule,_x,_rayon];
      _condition = format ["(leader group player distance getpos thistrigger) < %1 + 200",_rayon];
      _quandactiver = "[15,(getpos thistrigger),800] execvm 'h-occupations\h-factions\Violet\traficroutier\creationsvehicules.sqf'";
      _quanddesactiver = "";

      _declencheur = createtrigger ["emptydetector",_x];
      _declencheur settriggerarea [_rayon,_rayon,0,false];
      _declencheur settriggeractivation ["west","present",true];
      _declencheur setTriggerStatements [_condition,_quandactiver,_quanddesactiver];

      if(_x inArea [(getMarkerPos "hgbase"),_rayon,_rayon,0,false]) then {deletevehicle _declencheur};
  } foreach nearestLocations [getmarkerpos "hposcentre",["NameCityCapital","NameCity","NameVillage"],10000];
