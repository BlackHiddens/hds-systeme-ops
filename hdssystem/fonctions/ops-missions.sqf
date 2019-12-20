/*
Par : Hiddens 0.0.1.0

Descriptions : permet de générer une suites de missions aléatoire avec une ou plusieurs tâches.
les missions sont séparé par un temps aléatoire.

0 : <entier> taille du rayon d'action de la mission
1 : <entier> faction généré 0,1,2,3,4,5,6
2 : <entier> Nombre de missions généré
3 : <entier> ratio de difficulté de la mission
4 : <tableau> liste des lieux (localisation) où les missions peuvent apparaitre
5 : <booleen> Civil sur place ?
6 : <booleen> faction aléatoire ? ignore la faction si vrai

exemple:
[700,0,2,1,['NameCity','NameLocal','NameVillage'],true,false,3] spawn fnc_hds_missions;
*/

params ["_rayon","_faction","_nbsmissions","_difficulter","_typelocalisation","_civil","_aleatoirefaction","_nombre_de_taches"];
_Factionennemi = (_this select 1);
nombre_de_missions = (_this select 2);publicVariable "nombre_de_missions";

//Couvrir l'intégraliter de la carte pour la recherche d'une position pour une mission
_localiter = nearestLocations [[0,0,0],(_this select 4),40000];
//tant que le nombre max de mission n'est pas atteint alors dérouler la création de mission une par une
while {nombre_de_missions > 0} do {
  tache_effectuee = 0;publicVariable "tache_effectuee";

  if(hdssysteme)then{[format['%1 : Création de la mission en cours',hdsversion]] remoteexeccall ['systemChat',0]};
  _nombre_de_missions = nombre_de_missions;
  _lieudemission = locationposition (selectrandom _localiter);
//Attendre qu'il y est des joueurs sur le serveur
  waituntil {count allplayers > 0};
  sleep 10;
  if(hdssysteme)then{[format['%1 : Joueurs détectés sur le serveur',hdsversion]] remoteexeccall ['systemChat',0]};


//Génération d'une occupation ennemi
  if((_this select 6)isequalto true)then{
    _Factionennemi = (selectrandom HFactionennemi);
    if(hdssysteme)then{[format['%1 : Faction aléatoire sélectionnée',hdsversion]] remoteexeccall ['systemChat',0]};
    [_lieudemission,(_this select 3),_Factionennemi,(_this select 0),false] spawn fnc_hds_occupations;
    [_lieudemission,(_this select 0)*3,_Factionennemi,1,((_this select 3)+1)] spawn fnc_tactique_plannification;
  }else{
    if(hdssysteme)then{[format['%1 : Faction spécifique sélectionnée',hdsversion]] remoteexeccall ['systemChat',0]};
    [_lieudemission,(_this select 3),(_this select 1),(_this select 0),false] spawn fnc_hds_occupations;
    [_lieudemission,(_this select 0)*2,(_this select 1),1,((_this select 3)+1)] spawn fnc_tactique_plannification;
  };
//Génération des civils
  if((_this select 5))then{
    hds_population = 0;
    if(_Factionennemi isequalto 6) then {hds_population = 1};
    if(_Factionennemi isequalto 4) then {hds_population = 2};
    if(_Factionennemi isequalto 5) then {hds_population = 3};
    if((isnil "_Factionennemi" isequalto false) and ((_this select 1) isequalto 4)) then {hds_population = 2};
    if((isnil "_Factionennemi" isequalto false) and ((_this select 1) isequalto 5)) then {hds_population = 3};
    [_lieudemission,0,(_this select 0),hds_population,false] spawn fnc_occupations_civil_init;
    if(hdssysteme)then{[format['%1 : création de la population',hdsversion]] remoteexeccall ['systemChat',0]};
  };

  if(boutiqueactive)then{
    comptedemissions = (((_this select 0)/3)*(_this select 3));
  };
  if(hdssysteme)then{[format['%1 : création de la mission terminée',hdsversion]] remoteexeccall ['systemChat',0]};
  //Création d'un ou plusieurs objetifs aléatoires
  for "_i" from 1 to (_this select 7) do {
    sleep 5;
    [_lieudemission,((_this select 0)/1.5),(_this select 1)] spawn fnc_objectif_aleatoire;
  };

  {(group _x) enableDynamicSimulation true} foreach AllUnits inAreaArray [_lieudemission,(_this select 0),(_this select 0),0,false,100];
  {_x enableDynamicSimulation true} foreach Vehicles inAreaArray [_lieudemission,(_this select 0),(_this select 0),0,false,100];

  waituntil {tache_effectuee isequalto (_this select 7)};
  if(hdssysteme)then{[format['%1 : Mission terminée',hdsversion]] remoteexeccall ['systemChat',0]};
  _tempsmissionssuivante = round random 600;
  pointdevehicule = pointdevehicule + (_this select 7);publicVariable "pointdevehicule";
  [format['%1 : %2 point(s) de véhicule ont été ajouté(s)',hdsversion,(_this select 7)]] remoteexeccall ['systemChat',0];

  while{_tempsmissionssuivante < 200} do {_tempsmissionssuivante = round random 600};
  if(hdssysteme)then{[format['%1 : attendre %2 secondes, analyse de la région en cours ...',hdsversion,_tempsmissionssuivante]] remoteexeccall ['systemChat',0]};
  sleep _tempsmissionssuivante;
  if(hdssysteme)then{[format['%1 : Nettoyage du secteur de mission',hdsversion]] remoteexeccall ['systemChat',0]};

  {deleteVehicle _x} foreach  (nearestObjects [_lieudemission,["Man","Tank","Car","Helicopter","Civilian","logic"],(_this select 0)]);
  {if(getmarkerpos _x distance _lieudemission < (_this select 0))then{deletemarker _x}} foreach allMapMarkers;

};


/* Type de localisation

"NameVillage", - Village
"NameCity", - Ville
"Name", - Endroit commun
"NameLocal", - Endroit particulier
"Strategic" - Base militaire
*/
