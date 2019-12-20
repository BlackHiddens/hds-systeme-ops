/*
  Description : Initialisation du serveur à son démarrage.
  Ne s'exécute d'une seul fois et uniquement pour le serveur
*/

"Group" setDynamicSimulationDistance 1000;
"Vehicle" setDynamicSimulationDistance 1000;
"EmptyVehicle" setDynamicSimulationDistance 800;
"EmptyVehicle" setDynamicSimulationDistance 30;

//Multiplication de l'acceleration du temps (défaut : 1)
setTimeMultiplier 1;
/*
 par défaut tous les camps militaire et paramilitaire sont alliées avec les civils
*/

//independant et east sont allié
independent setFriend [East,1];
East setFriend [independent,1];

//west et east sont ennemi
west setFriend [East,0];
East setFriend [west,0];

//independant et west sont ennemi
independent setFriend [west,0];
west setFriend [independent,0];

//les civils sont alliés avec tous le monde
civilian setFriend [west,1];
civilian setFriend [east,1];
civilian setFriend [independent,1];

//création un point de réapparition ainsi qu'un marqueur de zone à l'emplacement du premier joueurs se connectant au serveur


{
  waituntil {count allPlayers > 0};
  waituntil {isTouchingGround selectrandom allplayers};

  [west,getposASL selectrandom allplayers,(hdsnombase select 0)] call BIS_fnc_addRespawnPosition;
  //(_this select 0) setVehicleVarName "respawn_WEST";

  hds_marqueur_base = [
  "hds_marqueur_base",
  getpos selectrandom allplayers,
  "ellipse",
  [100,100],
  "BRUSH:","SolidBorder",
  "COLOR:","colorwest",
  "PERSIST"
  ] call cba_fnc_createmarker;

} spawn BIS_fnc_spawn;


hds_administrateur_alpha = (creategroup sidelogic) createunit ["ModuleCurator_F",[0,0,0],[],0,"NONE"];
hds_administrateur_alpha setvariable ['BIS_fnc_initModules_disableAutoActivation',false,true];
hds_administrateur_alpha setvariable ['Owner','#adminlogged'];
[hds_administrateur_alpha] call ace_modules_fnc_moduleInit;
//[hds_administrateur_alpha,[player],true] call ace_zeus_fnc_bi_moduleCurator;

//traduction de texte
hds_txt_objectif_communication = localize "str_hds_objectif_communication";
hds_txt_objectif_otage = localize "str_hds_objectif_otage";
hds_txt_objectif_logistique = localize "str_hds_objectif_logistique";
hds_txt_objectif_hvt = localize "str_hds_objectif_hvt";
hds_txt_objectif_infos = localize "str_hds_objectif_infos";
hds_txt_objectif_piratage = localize "str_hds_objectif_piratage";
hds_txt_objectif_structure = localize "str_hds_objectif_structure";
hds_txt_objectif_cache = localize "str_hds_objectif_cache";
hds_txt_objectif_arrestation = localize "str_hds_objectif_arrestation";
hds_txt_objectif_capture = localize "str_hds_objectif_capture";
hds_txt_objectif_securiser = localize "str_hds_objectif_securiser";

hds_txt_virtualgarage_acheter = localize "str_hds_virtualgarage_acheter";
hds_txt_virtualgarage_description = localize "str_hds_virtualgarage_description";

hds_txt_fonctions_medical_santestable = localize "str_hds_fonctions_medical_santestable";
hds_txt_fonctions_arsenal_libinteraction = localize "str_hds_fonctions_arsenal_libinteraction";
hds_txt_fonctions_divers_libcommandervehicule = localize "str_hds_fonctions_divers_libcommandervehicule";
hds_txt_fonctions_divers_librecruterequipe = localize "str_hds_fonctions_divers_librecruterequipe";
hds_txt_fonctions_divers_libdebloquermission = localize "str_hds_fonctions_divers_libdebloquermission";
hds_txt_fonctions_divers_libdebloquermissionignorer = localize "str_hds_fonctions_divers_libdebloquermissionignorer";
hds_txt_fonctions_divers_libdebloquermissionnonexiste = localize "str_hds_fonctions_divers_libdebloquermissionnonexiste";
hds_txt_fonctions_divers_libsautenparachute = localize "str_hds_fonctions_divers_libsautenparachute";
hds_txt_fonctions_divers_descsautenparachute = localize "str_hds_fonctions_divers_descsautenparachute";

//module_zeus = [[0,0,0],0,"ModuleCurator_F",sidelogic] call bis_fnc_spawnvehicle;
