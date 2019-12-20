/*
  place des civils dans la zone
  0 : <positions> position centrale
  1 : <entier> ratio d'occupation
  2 : <entier> Taille de la zone d'occupation en mètres
  3 : <entier> Nationnalité des civils généré 0 : Europeens, 1 : Arabes, 2 : Africaine, 3 : Russe
  4 : <booleen> Afficher un marqueur sur le secteur d'occupation

  exemple : [[0,0,0],0,300,0,false] call fnc_occupations_civil_init;

*/
params ["_centre","_ratio","_taille","_nationalite","_marqueurvisible"];

//Creer un marqueur
_secteur = [(format ["hds_occups_civil_%1",round random 900]),(_this select 0),"Ellipse",[(_this select 2),(_this select 2)],
"BRUSH:","SolidBorder",
"COLOR:","colorCivilian"
] call cba_fnc_createmarker;

if((_this select 4) isequalto false)then{_secteur setMarkerAlpha 0};
if(hdssysteme)then{_secteur setMarkerAlpha 1};

_TousObjetsTrouve = [(_this select 2),(_this select 0),['house']] call fnc_objectif_liste_batimentsetplaces;
for "_i" from 1 to ((count (_TousObjetsTrouve select 0)/3) + (_this select 1)) do {

  //les europeens --------------------------------------------
  if((_this select 3) isequalto 0)exitwith{
  if(hdssysteme)then{["hds-système : création d'une population civil europeens"] remoteexeccall ["systemChat",0]};
  //Casanier
  _homme_casanier = [(_this select 0),180,(SelectRandom hds_liste_civil_europeens),civilian] call bis_fnc_spawnvehicle;
  [(_this select 0),nil,[(_homme_casanier select 0)],(_this select 2),1,false,true] call ace_ai_fnc_garrison;
  [(_homme_casanier select 0),"SIT_LOW_U","NONE"] call BIS_fnc_ambientAnim;
  (_homme_casanier select 0) enableDynamicSimulation true;
  //Pietons
  _homme = [(_this select 0),180,(SelectRandom hds_liste_civil_europeens),civilian] call bis_fnc_spawnvehicle;
  [(_homme select 2),(_this select 0),((_this select 2)/3)] call bis_fnc_taskpatrol;
  (_homme select 0) enableDynamicSimulation true;
  };

  //les arabes (Project Opfor)--------------------------------------------
  if((_this select 3) isequalto 1)then{
  if(hdssysteme)then{["hds-système : création d'une population civil arabes"] remoteexeccall ["systemChat",0]};
  //Casanier
  _homme_casanier  = [(_this select 0),180,(SelectRandom hds_liste_civil_arabes),civilian] call bis_fnc_spawnvehicle;
  [(_this select 0),nil,[(_homme_casanier select 0)],(_this select 2),1,false,true] call ace_ai_fnc_garrison;
  [(_homme_casanier select 0),"SIT_LOW_U","NONE"] call BIS_fnc_ambientAnim;
  (_homme_casanier select 0) enableDynamicSimulation true;
  //Pietons
  _homme = [(_this select 0),180,(SelectRandom hds_liste_civil_arabes),civilian] call bis_fnc_spawnvehicle;
  [(_homme select 2),(_this select 0),((_this select 2)/3)] call bis_fnc_taskpatrol;
  (_homme select 0) enableDynamicSimulation true;
  }else{};

  //les africain (Project Opfor)--------------------------------------------
  if(((_this select 3) isequalto 2) and opforactive)then{
  if(hdssysteme)then{["hds-système : création d'une population civil africaine"] remoteexeccall ["systemChat",0]};
  //Casanier
  _homme_casanier = [(_this select 0),180,(SelectRandom hds_liste_civil_africain),civilian] call bis_fnc_spawnvehicle;
  [(_this select 0),nil,[(_homme_casanier select 0)],(_this select 2),1,false,true] call ace_ai_fnc_garrison;
  [(_homme_casanier select 0),"SIT_LOW_U","NONE"] call BIS_fnc_ambientAnim;
  (_homme_casanier select 0) enableDynamicSimulation true;
  //Pietons
  _homme = [(_this select 0),180,(SelectRandom hds_liste_civil_africain),civilian] call bis_fnc_spawnvehicle;
  [(_homme select 2),(_this select 0),((_this select 2)/3)] call bis_fnc_taskpatrol;
  (_homme select 0) enableDynamicSimulation true;
  }else{};


  //les russe (RDS Civilian pack)--------------------------------------------
  if(((_this select 3) isequalto 3) and rdsactive)then{
  if(hdssysteme)then{["hds-système : création d'une population civil russe"] remoteexeccall ["systemChat",0]};
  //Casanier
  _homme_casanier = [(_this select 0),180,(SelectRandom hds_liste_civil_russe),civilian] call bis_fnc_spawnvehicle;
  [(_this select 0),nil,[(_homme_casanier select 0)],(_this select 2),1,false,true] call ace_ai_fnc_garrison;
  [(_homme_casanier select 0),"SIT_LOW_U","NONE"] call BIS_fnc_ambientAnim;
  (_homme_casanier select 0) enableDynamicSimulation true;
  //Pietons
  _homme = [(_this select 0),180,(SelectRandom hds_liste_civil_russe),civilian] call bis_fnc_spawnvehicle;
  [(_homme select 2),(_this select 0),((_this select 2)/3)] call bis_fnc_taskpatrol;
  (_homme select 0) enableDynamicSimulation true;
  }else{};

};
