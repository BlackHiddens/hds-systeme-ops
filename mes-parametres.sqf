//Mes outils
hdsversion = "ai-hds-systeme.stable";   //Nom de la version du hds-systeme-ops. Si le hds-systeme-ops annonce des choses il le fera sous ce nom
hdsnombase = ["hds-ros-base"];  //placer un marqueur sur votre base afin qu'elle soit prise en compte par le script (facultatif mais conseillé en mission automatique)
hdssysteme = false;              //hds-systeme-ops en mode débug. il annonce tous ce qu'il fait
//Tous mes objets scriptés
lelieuestunvehicule = false;     //Le lieu médical est un véhicule ? sinon c'est un lieu
sontdeslieudesoin = [soins];    //Liste des objets qui sont des lieux de soins
sontdesarsenales = [arsenal_console];          //Liste des objets qui sont des arsenales
sontdespostesdecommunications = [arsenal_console]; //liste des objets qui sont des terminal de communications (Il met à disposition des ressources pour les joueurs)
estungarage = [arsenal_console,[8237.49,10049.9,-7.62939e-006]];//[<objet>,<position>]
estunravitaillement = [[8237.49,10049.9,-7.62939e-006],10]; //[<position>,<rayon>]

sontdesmanageurs = ["chef_one","chef_two","invite_0"];
sontdesexpertcoms = ["communication_one","communication_two","invite_1"];
sontdesmedecins = ["medecin_one","medecin_two","invite_3","invite_4"];
sontdesingenieurs = ["mecano_one","mecano_two","invite_2"];
sontdespilotes = ["pilote_one","pilote_two","invite_5"];
sontdescontractor = ["contractor_1","contractor_2","contractor_3","contractor_4","contractor_5","contractor_6"];

sontdesappuismanageurs = [radio_appui];
sontdesappuisexoertcoms = [radio_appui];
sontdesappuismedicals = [radio_appui];
sontdesappuisingenieurs = [radio_appui];
sontdesappuispilotes = [radio_appui];
sontdesappuiscontractor = [radio_appui];

//Activation des fonctions personnalisées
boutiqueactive = false;//Est-ce que le mode d'argent est activé ?
modehardactive = false;//Est-ce que mode limination d'equipement est activé ?
sauvegarderlesequipements = false; //Sauvegarder et charge les equipements des joueurs sur le serveur

//Détection automatique des addons présent dans la mission afin de les utiliser.
if (isClass(configFile >> "CfgPatches" >> "ace_main"))then{aceestactive = true}else{aceestactive = false};          //ace
if (isClass(configFile >> "CfgPatches" >> "po_main"))then{opforactive = true}else{opforactive = false};             //projectOpfor
if (isClass(configFile >> "CfgPatches" >> "rhs_main"))then{afrfactive = true}else{afrfactive = false};              //rhsafrf
if (isClass(configFile >> "CfgPatches" >> "rhsusf_main"))then{usafactive = true}else{usafactive = false};           //rhsusaf
if (isClass(configFile >> "CfgPatches" >> "FFCamoPack_Common"))then{foxforactive = true}else{foxforactive = false}; //foxforCamoPack
if (isClass(configFile >> "CfgPatches" >> "COS_equips"))then{cosactive = true}else{cosforactive = false};           //C.O.S
if (isClass(configFile >> "CfgPatches" >> "rds_A2_Civilians"))then{rdsactive = true}else{rdsactive = false};        //RDS Civilian Pack
if (isClass(configFile >> "CfgPatches" >> "Project_Numb_3"))then{numbactive = true}else{numbactive = false};        //Project_Numb_3 activé

//Administrateur du serveur où est héberger la mission
hds_administrateurs = [
"76561198024919122", //Hidden's
"76561198051943976", //Defconleader
"76561197982924970"  //Adam's
];
//----------------------Fonctions (Pour les utilisateurs avancé)-----------------------------------------------
prix = [
  0.0,//Prix de l'arme principale
  0.0,  //Prix de l'arme secondaire
  0.0,  //Prix du pistolet
  49.99, //Prix d'un chargeur
  119.99,//Prix d'un sac à dos
  689.99,//Prix d'un module principale
  499.99,//Prix d'un module de pistolet
  25.99, //Prix d'un objet
  80.00, //Prix d'une paire de lunette ou d'un bandane
  559.00,//Prix vision nocture
  20.00, //Prix gilet
  99.99 //prix chapeaux et casques
];
fnc_hds_arsenaux = compile preprocessFile "hdssystem\fonctions\arsenaux.sqf";//[Liste d'objet:<tableau>] spawn fnc_hds_arsenaux;
  fnc_hds_arsenal_complet = compile preprocessFile "hdssystem\fonctions\arsenaux\complet.sqf";
  fnc_hds_arsenal_gios = compile preprocessFile "hdssystem\fonctions\arsenaux\gios.sqf";
  fnc_hds_arsenal_prive = compile preprocessFile "hdssystem\fonctions\arsenaux\prive.sqf";
  fnc_hds_arsenal_afghan = compile preprocessFile "hdssystem\fonctions\arsenaux\afghan.sqf";
  fnc_hds_arsenal_numb = compile preprocessFile "hdssystem\fonctions\arsenaux\numb.sqf";
  fnc_hds_poste_de_communication = compile preprocessFile "hdssystem\fonctions\postedecommunication.sqf";
fnc_hds_garages = compile preprocessFile "virtualgarage\virtualgarage.sqf";
fnc_hds_ravitaillement = compile preprocessFile "hdssystem\fonctions\ops-rearmement.sqf";
fnc_hds_medical = compile preprocessFile "hdssystem\fonctions\lieumedical.sqf";//[Liste d'objet:<tableau>] spawn fnc_hds_medical;
fnc_hds_peuposerattelle = compile preprocessFile "hdssystem\fonctions\poseattelle.sqf";//[<Utilisateur:Objet>] spawn fnc_hds_peuposerattelle;
fnc_hds_pointreapparition = compile preprocessFile "hdssystem\fonctions\pointderespawn.sqf";//[] spawn fnc_hds_pointreapparition;
fnc_hds_creerequipages = compile preprocessFile "hdssystem\fonctions\generationequipages.sqf";//[<Utilisateur:objet>] spawn fnc_hds_pointreapparition;
fnc_hds_consteste =  compile preprocessFile "hdssystem\fonctions\ops-conteste.sqf";//[<faction:entier>,<ratio:entier>] spawn fnc_hds_carteconsteste;
fnc_ace_garnir = compile preprocessFile "hdssystem\fonctions\garnirhabitations.sqf";//[<marqueur>,<tableau>,<entier>,<booleen>] spawn fnc_ace_garnirhabitation;
fnc_fnc_informations = compile preprocessFile "hdssystem\fonctions\informations.sqf";//[<texte>] spawn fnc_fnc_informations;
fnc_hds_introduction = compile preprocessFile "hdssystem\fonctions\introscenario.sqf";
fnc_hds_fin = compile preprocessFile "hdssystem\fonctions\finscenario.sqf";
fnc_hds_missions = compile preprocessFile "hdssystem\fonctions\ops-missions.sqf";//[<entier>:rayon,<entier>:faction,<entier>:nombremissions] spawn fnc_hds_missions;
fnc_hds_populace = compile preprocessFile "hdssystem\fonctions\ops-populace.sqf";//[<entier>:nationnalité,<entier>:ratio,<entier>:rayon] spawn fnc_hds_populace;
fnc_engima_traffic = compile preprocessFile "engima\traffic\init.sqf";
fnc_hds_boutique = compile preprocessFile "hdssystem\fonctions\argent\boutiques.sqf";
fnc_hds_ajoutaction = compile preprocessFile "hdssystem\fonctions\ajouteraction.sqf";
fnc_hds_saveequipement = compile preprocessFile "hdssystem\fonctions\ops-saveequipement.sqf";
fnc_hds_presence_hostile = compile preprocessFile "hdssystem\fonctions\ops-presence-hostile.sqf";
fnc_hds_soustitre = compile preprocessFile "hdssystem\fonctions\soustitre.sqf";
fnc_hds_demandeurderenforts = compile preprocessFile "hdssystem\fonctions\ops-demanderdesrenforts.sqf";
fnc_hds_utilisateurdegcam = compile preprocessFile "hdssystem\fonctions\ops-utilisateurdegcam.sqf";
fnc_support_avions = compile preprocessFile "hdssystem\fonctions\demandebombardement.sqf";
fnc_hds_action_saut_parachute = compile preprocessFile "hdssystem\fonctions\sauteenparachute.sqf";
//exécution natif -- Ne pas supprimer
