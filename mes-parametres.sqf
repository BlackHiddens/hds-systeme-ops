// ═══════════════════════════════════════════════════════════
// HDS Paramètres — NewHDS (Stratis)
// Prérequis mod : CBA_A3 uniquement. Tout le reste est optionnel
// et détecté à chaud (voir « Détection addons » plus bas).
// ═══════════════════════════════════════════════════════════

hdsversion  = "newhds.stratis";
hdsnombase  = ["hds_base_newhds"];
// ─── Mode debug ───
// Ce qu'il allume : les traces dans le RPT, les messages en chat, les
// cercles rouges de zone d'occupation et les marqueurs d'ennemis sur la
// carte. Autrement dit, tout ce qui ne doit pas se voir en ligne.
//
// Il ne faut pas avoir à s'en souvenir avant une mise en ligne : la
// valeur se déduit de qui fait tourner la mission.
//
//   "AUTO"  → allumé quand c'est toi qui l'héberges sur ta machine
//             (aperçu d'éditeur, serveur local), éteint dès qu'elle
//             tourne sur un serveur dédié. À laisser.
//   true    → forcé allumé, même en ligne.
//   false   → forcé éteint, même en local.
//
// isServer && hasInterface, c'est exactement « la machine qui héberge
// est aussi celle où je joue ». Un serveur dédié n'a pas d'interface,
// et un client n'est pas serveur : les deux retombent sur false.
//
// Le réglage CBA « Mode debug » (Échap → Options → Addons → HDS) passe
// par-dessus en cours de partie, et comme il est déclaré global c'est
// la valeur du serveur qui fait loi pour tout le monde.
hds_debug_choix = "AUTO";
hdssysteme = if (hds_debug_choix isEqualType true) then {
    hds_debug_choix
} else {
    isServer && hasInterface
};

// Opacite des formes que le mode debug allume : cercles de secteur,
// zones de combat. A 1 elles noircissent la carte et cachent le
// terrain ; 0.3 laisse lire ce qu'il y a dessous. Ne s'applique qu'aux
// marqueurs que le debug rend visibles : celui qu'une mission demande
// pour elle-meme garde l'opacite qu'elle a choisie.
hds_debug_alpha = 0.3;

// ─── Rôles joueurs ───
// Des CHAÎNES : comparées à vehicleVarName player.
// Les noms correspondent à ceux posés dans mission.sqm :
//   chef_alpha_0        B_Soldier_TL_F   chef d'equipe
//   mitrailleur_alpha_0 B_soldier_AR_F
//   grenadier_alpha_0   B_Soldier_GL_F
//   antichar_alpha_0    B_soldier_LAT_F
//
// Le chef est « manageur » : il reçoit les traits ingénieur ET médecin,
// ce qui suffit à couvrir les deux besoins avec une équipe de quatre.
sontdesmanageurs    = ["chef_alpha_0"];
sontdesexpertcoms   = ["grenadier_alpha_0"];   // non lu par le chemin vivant (voir note en bas)
sontdesmedecins     = [];                      // couvert par le manageur
sontdesingenieurs   = [];                      // couvert par le manageur
sontdespilotes      = [];
sontdescontractor   = [];

sontdesappuismanageurs  = [];
sontdesappuisexpertcoms = [];
sontdesappuismedicals   = [];
sontdesappuisingenieurs = [];
sontdesappuispilotes    = [];
sontdesappuiscontractor = [];

// ─── Objets de la base ───
// Des OBJETS, pas des chaînes : ce sont les noms de variables de
// mission.sqm, résolus directement.
//   arsenal_alpha_0/1  B_supplyCrate_F
//   soins_alpha_0      Box_NATO_Support_F
//   console_alpha_0    Land_Laptop_unfolded_F
// initserver.sqf les repose au sol après chargement, pour qu'un
// décalage de terrain ne les laisse pas flotter.
sontdeslieudesoin             = [soins_alpha_0];
sontdesarsenales              = [arsenal_alpha_0, arsenal_alpha_1];
sontdespostesdecommunications = [console_alpha_0];

lelieuestunvehicule = false;
estunravitaillement = [[0, 0, 0], 10];

// ─── Options ───
boutiqueactive            = false;
modehardactive            = false;
sauvegarderlesequipements = false;

// ─── Détection addons (soft dependencies) ───
// Aucun de ces mods n'est requis : chaque fonctionnalité qui en dépend
// a un repli vanilla/CBA dans hdssystem\compat\h-compat.sqf.
cbaestactive  = isClass (configFile >> "CfgPatches" >> "cba_main");
aceestactive  = isClass (configFile >> "CfgPatches" >> "ace_main");
opforactive   = isClass (configFile >> "CfgPatches" >> "po_main");
afrfactive    = isClass (configFile >> "CfgPatches" >> "rhs_main");
usafactive    = isClass (configFile >> "CfgPatches" >> "rhsusf_main");
// GREF et SAF manquaient : ils étaient chargés, contribuaient au registre
// (d'où 205 factions trouvées) mais n'apparaissaient nulle part.
grefactive    = isClass (configFile >> "CfgPatches" >> "rhsgref_main");
safactive     = isClass (configFile >> "CfgPatches" >> "rhssaf_main");
foxforactive  = isClass (configFile >> "CfgPatches" >> "FFCamoPack_Common");
cosactive     = isClass (configFile >> "CfgPatches" >> "COS_equips");
rdsactive     = isClass (configFile >> "CfgPatches" >> "rds_A2_Civilians");
numbactive    = isClass (configFile >> "CfgPatches" >> "Project_Numb_3");

// ─── Admins ───
hds_administrateurs = ["76561198024919122"];

prix = [0,0,0,0,0,0,0,0,0,0,0];

// ─── Localisation (textes d'interface) ───
//
// Il n'y a pas de stringtable.xml dans cette mission, et les deux
// fichiers qui définissaient ces 46 variables par « localize » —
// hdssystem\init-serveur.sqf et init-client.sqf — ne sont appelés par
// rien. Les textes sont donc écrits ici, en clair. Le jour où une
// stringtable arrive, c'est cette liste qu'on remplace.
hds_txt_fonctions_arsenal_libinteraction = "Accéder à la boutique";
hds_txt_fonctions_medical_santestable    = "Santé stabilisée.";

// Noms des objectifs, lus par fnc_objectif_aleatoire — donc par
// fnc_hds_missions. Sans eux, la première variable indéfinie avortait
// fnc_objectif_aleatoire et aucune tâche n'était créée : la mission
// attendait alors indéfiniment des tâches qui ne viendraient jamais.
hds_txt_objectif_communication = "Interrompre les communications";
hds_txt_objectif_otage         = "Libérer un otage";
hds_txt_objectif_logistique    = "Détruire la logistique";
hds_txt_objectif_hvt           = "Éliminer une cible de valeur";
hds_txt_objectif_infos         = "Récupérer des renseignements";
hds_txt_objectif_piratage      = "Pirater un terminal";
hds_txt_objectif_structure     = "Capturer et tenir une structure";
hds_txt_objectif_cache         = "Détruire une cache d'armes";
hds_txt_objectif_arrestation   = "Procéder à une arrestation";
hds_txt_objectif_securiser     = "Sécuriser le secteur";

// ─── Tours de guet ───
// Dans un secteur d'occupation, ces bâtiments-là reçoivent au moins un
// homme, quoi qu'en dise le ratio de garnison : une tour vide ne sert
// à rien. Les autres bâtiments ne changent pas.
//
// Classes vanilla vérifiées dans les archives du jeu. Les tours des
// mods et des cartes tierces sont reconnues à la mesure (haute et
// étroite, avec une place en hauteur), donc cette liste n'a pas à être
// exhaustive — elle sert à nommer les cas sûrs. Ajoute-s-y ce que la
// mesure raterait.
hds_miradors_classes = [
    "Land_Cargo_Patrol_V1_F", "Land_Cargo_Patrol_V2_F",
    "Land_Cargo_Patrol_V3_F", "Land_Cargo_Patrol_V4_F",
    "Land_Cargo_Tower_V1_F",  "Land_Cargo_Tower_V2_F",
    "Land_Cargo_Tower_V3_F",  "Land_Cargo_Tower_V4_F",
    "Land_Cargo_Tower_V1_No1_F", "Land_Cargo_Tower_V1_No2_F",
    "Land_Cargo_Tower_V1_No3_F", "Land_Cargo_Tower_V1_No4_F",
    "Land_Cargo_Tower_V1_No5_F", "Land_Cargo_Tower_V1_No6_F",
    "Land_Cargo_Tower_V1_No7_F",
    "Land_TTowerBig_1_F", "Land_TTowerBig_2_F"
];

// ─── Journal d'exécution (en premier : tout le reste peut y écrire) ───
#include "hdssystem\modules\journal\h-init.sqf"

// ─── Couche de compatibilité ───
#include "hdssystem\compat\h-compat.sqf"

// ─── Mode debug réversible ───
// Avant les réglages : leur script de changement appelle
// hds_fnc_debugAppliquer, qui doit donc exister d'abord.
#include "hdssystem\debug-mode.sqf"

// ─── Réglages en jeu (menu CBA) ───
// Après le journal, dont ces réglages se servent pour signaler une
// erreur. Des deux côtés : le menu doit exister chez les clients.
#include "hdssystem\modules\reglages\h-init.sqf"

// ─── Fonctions HDS (fichiers) ───
fnc_hds_ajoutaction            = compile preprocessFile "hdssystem\fonctions\ajouteraction.sqf";
fnc_hds_arsenaux               = compile preprocessFile "hdssystem\fonctions\arsenaux.sqf";
fnc_hds_medical                = compile preprocessFile "hdssystem\fonctions\lieumedical.sqf";
fnc_hds_poste_de_communication = compile preprocessFile "hdssystem\fonctions\postedecommunication.sqf";

// Circuit de patrouille sur les routes d'une zone, pour les
// equipes embarquees. Rend faux si la zone est sans route.
hds_fnc_circuitRoutier         = compile preprocessFile "hdssystem\fonctions\circuit-routier.sqf";

// Poste un homme dans chaque tour de guet d'un secteur.
hds_fnc_miradors               = compile preprocessFile "hdssystem\fonctions\miradors.sqf";

// ─── Renforts alliés : la partie CLIENT ───
// Ces trois fonctions tournent sur le client (carte, actions, chat).
// Elles étaient compilées dans modules\occupations\h-init.sqf, qui n'est
// chargé que par le serveur via init-systeme.sqf : elles n'existaient
// donc sur aucun client, alors que c'est précisément là qu'on les
// appelle. Ici, mes-parametres.sqf est inclus des deux côtés.
fnc_renfort_allie        = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-RenfortAllie.sqf";
fnc_generer_groupe       = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\recrueperso.sqf";
fnc_EstUnTerminalRenfort = compile preprocessFile "hdssystem\modules\occupations\h-renfortallie\h-AjouterActionRenfort.sqf";

// ─── Réception de l'export du registre (côté client) ───
// Le serveur construit le JSON, le client le met dans son presse-papier.
hds_fnc_factionsExportRecoit = compile preprocessFile "hdssystem\modules\factions\fncs\export-recoit.sqf";

/*
 * NOTE — rôles effectivement lus
 * Dans NewHDS, seuls sontdesmanageurs, sontdesmedecins et
 * sontdesingenieurs sont lus (initplayerlocal.sqf, onplayerrespawn.sqf).
 * sontdesexpertcoms, sontdespilotes et sontdescontractor ne sont lus que
 * par hdssystem\init-client.sqf et init-reapparition.sqf, qui ne sont
 * chargés par rien pour l'instant. Ils sont renseignés quand même : la
 * donnée est juste, elle servira si ces fichiers sont remis en service.
 */

/*
 * NOTE — fnc_hds_boutique
 * hdssystem\fonctions\arsenaux.sqf pose une action qui l'appelle, mais
 * la fonction n'existe nulle part dans cette version. Le piège est
 * dormant : il faut boutiqueactive ET ACE pour l'atteindre, et il
 * n'éclaterait qu'au moment où un joueur déclenche l'action, pas au
 * chargement. Le stub ci-dessous le rend inoffensif et dit pourquoi.
 */

// ─── Fonctions stub (modules non déployés dans cette version) ───
fnc_hds_boutique          = { hint "La boutique n'est pas déployée dans cette version."; };
fnc_fnc_informations      = { params ["_texte"]; hint _texte; };
fnc_hds_ravitaillement    = { };
fnc_hds_saveequipement    = { };
fnc_hds_creerequipages    = { };
fnc_hds_peuposerattelle   = { };
fnc_hds_pointreapparition = { };
fnc_hds_soustitre         = { };
