/*
 * hdssystem\modules\factions\h-init.sqf
 * ─────────────────────────────────────────────────────────────
 * HDS — Module Factions
 *
 * Construit au démarrage un registre des factions RÉELLEMENT
 * présentes sur le serveur, en interrogeant la config vanilla :
 *
 *   CfgGroups         → compositions de groupes, rangées par faction
 *   CfgFactionClasses → noms affichables
 *   CfgVehicles       → véhicules, rangés par faction
 *
 * PRÉREQUIS : aucun. Pas une ligne de CBA ici, pas un classname de
 * mod en dur. Le registre contient ce que le serveur a et rien
 * d'autre : sur une install vanilla il y a les factions vanilla,
 * avec RHS il y a RHS en plus, sans qu'on touche à une ligne.
 *
 * Inclus depuis init-systeme.sqf, AVANT les autres modules.
 *
 * ── Le scan est asynchrone ──
 * Attendre le drapeau avant de consommer le registre :
 *     waitUntil { hds_factions_pret };
 *
 * ── Utilisation ──
 *   private _cfg = [east, "GARNISON"] call hds_fnc_factionGroupe;
 *   private _grp = [_pos, east, _cfg] call BIS_fnc_spawnGroup;
 *
 *   private _veh = ["OPF_F", "CAMION"] call hds_fnc_factionVehicule;
 *
 * Passer un SIDE (east) au lieu d'un id de faction ("OPF_F") laisse
 * le module déduire la faction de ce que la mission a posé dans
 * l'éditeur — voir fncs\faction-du-terrain.sqf.
 */

if (!isServer) exitWith {};

// ═══════════════════════════════════════════════════════════
// RÔLES DE COMPOSITION
// Ce que l'heuristique sait reconnaître dans un groupe CfgGroups.
// ═══════════════════════════════════════════════════════════
hds_factions_roles = [
    "FIRETEAM",   // 2 à 4 hommes à pied
    "SQUAD",      // 5 à 9 hommes à pied
    "SECTION",    // 10 hommes et plus
    "RECON",      // catégorie reconnaissance / forces spéciales / nageurs
    "SNIPER",     // tireurs d'élite
    "SUPPORT",    // appui : mortiers, armes statiques, sections d'armes
    "MOTORISE",   // groupe avec véhicule roulant de transport
    "MECANISE",   // groupe avec véhicule de combat d'infanterie
    "BLINDE",     // groupe avec char
    "AIR",        // groupe avec aéronef
    "NAVAL"       // groupe avec embarcation
];

// ═══════════════════════════════════════════════════════════
// RÔLES DE VÉHICULE
// ═══════════════════════════════════════════════════════════
hds_factions_roles_veh = [
    "LEGER", "ARME", "CAMION", "MECANISE", "BLINDE",
    "HELICO_TRANSPORT", "HELICO_ARME", "AVION", "NAVAL"
];

// ═══════════════════════════════════════════════════════════
// INTENTIONS → ordre de préférence des rôles
//
// Le reste du système demande une INTENTION ("je veux garnir ce
// village"), pas un rôle et surtout pas un classname. Le module
// descend la liste jusqu'à trouver quelque chose qui existe.
// ═══════════════════════════════════════════════════════════
hds_factions_intentions = createHashMapFromArray [
    ["GARNISON",   ["SQUAD", "SECTION", "FIRETEAM", "RECON"]],
    ["PATROUILLE", ["FIRETEAM", "SQUAD", "RECON", "SECTION"]],
    ["RECON",      ["RECON", "SNIPER", "FIRETEAM", "SQUAD"]],
    ["ASSAUT",     ["SECTION", "SQUAD", "FIRETEAM"]],
    ["SUPPORT",    ["SUPPORT", "SQUAD", "FIRETEAM"]],
    ["MOTORISE",   ["MOTORISE", "MECANISE", "SQUAD", "FIRETEAM"]],
    ["MECANISE",   ["MECANISE", "MOTORISE", "BLINDE", "SQUAD"]],
    ["BLINDE",     ["BLINDE", "MECANISE", "MOTORISE"]],
    ["AIR",        ["AIR"]],
    ["NAVAL",      ["NAVAL", "RECON", "FIRETEAM"]]
];

hds_factions_intentions_veh = createHashMapFromArray [
    ["TRANSPORT",   ["CAMION", "MECANISE", "LEGER", "ARME"]],
    ["PATROUILLE",  ["ARME", "LEGER", "CAMION"]],
    ["LEGER",       ["LEGER", "ARME", "CAMION"]],
    ["BLINDE",      ["BLINDE", "MECANISE", "ARME"]],
    ["HELICO",      ["HELICO_TRANSPORT", "HELICO_ARME"]],
    ["HELICO_ARME", ["HELICO_ARME", "HELICO_TRANSPORT"]],
    ["AVION",       ["AVION"]],
    ["NAVAL",       ["NAVAL"]]
];

// ═══════════════════════════════════════════════════════════
// FACTIONS VANILLA
// Servent de dernier repli : elles existent toujours, donc une
// demande ne peut jamais échouer faute de mod.
// ═══════════════════════════════════════════════════════════
hds_factions_vanilla = [
    "BLU_F", "BLU_G_F", "BLU_T_F", "BLU_CTRG_F", "BLU_GEN_F",
    "OPF_F", "OPF_G_F", "OPF_T_F", "OPF_V_F",
    "IND_F", "IND_G_F", "IND_C_F", "IND_L_F",
    "CIV_F", "CIV_IDAP_F"
];

// ═══════════════════════════════════════════════════════════
// COMPATIBILITÉ : anciens index de faction du système HDS
//
// Tout le code existant — et le générateur web — désigne les
// factions par un entier 0..7. On garde la correspondance pour que
// rien ne casse, mais ce n'est plus qu'une table de traduction :
// si la faction visée n'est pas installée, hds_fnc_factionResoudre
// retombe sur une faction du même camp au lieu de ne rien spawner.
// ═══════════════════════════════════════════════════════════
hds_factions_legacy = createHashMapFromArray [
    [0, ["OPF_F",           east]],         // CSAT
    [1, ["IND_F",           independent]],  // AAF
    [2, ["BLU_F",           west]],         // Américains (alliés)
    [3, ["OPF_G_F",         east]],         // FIA
    [4, ["LOP_BH",          east]],         // Boko Haram   (Project OPFOR)
    [5, ["rhs_faction_msv", east]],         // Russes       (RHS AFRF)
    [6, ["LOP_AM_OPF",      east]],         // Afghans      (Project OPFOR)
    [7, ["LOP_ISTS_OPF",    east]]          // État isl.    (Project OPFOR)
];

// ═══════════════════════════════════════════════════════════
// REGISTRES (remplis par le scan)
// ═══════════════════════════════════════════════════════════
// hds_factions : id de faction → hashmap
//   "id"      <STRING>   ex "OPF_F"
//   "nom"     <STRING>   nom affichable, ex "CSAT"
//   "side"    <SIDE>
//   "sideNom" <STRING>   "EAST" | "WEST" | "INDEP" | "CIV"
//   "groupes" <HASHMAP>  rôle → [entrées CfgGroups]
//   "veh"     <HASHMAP>  rôle → [classnames]
hds_factions          = createHashMap;
hds_factions_par_side = createHashMap;   // "EAST" → ["OPF_F", ...]
hds_factions_pret     = false;

// ═══════════════════════════════════════════════════════════
// CACHE DE GENRE PAR CLASSE
// ═══════════════════════════════════════════════════════════
// La première mesure sur un serveur avec RHS a donné 4426 ms de scan,
// pour 11585 groupes. Le coût ne venait pas du parcours de CfgGroups
// mais de la classification : chaque groupe interrogeait la config pour
// CHACUNE de ses unités (isClass, scope, isKindOf), soit de l'ordre de
// 90 000 lectures — alors que les mêmes quelques milliers de classes
// reviennent sans cesse d'un groupe à l'autre.
//
// On mémorise donc le verdict par classe :
//   classe → [_genre, _places, _aTourelle]
//     _genre      "ABSENT" | "MAN" | "AIR" | "SHIP" | "TANK"
//                 | "STATIC" | "ROULANT"
//     _places     transportSoldier
//     _aTourelle  <BOOL>
hds_factions_cache_genre = createHashMap;

// ═══════════════════════════════════════════════════════════
// OUTILS
// ═══════════════════════════════════════════════════════════
hds_fnc_factionsSideNom = {
    params [["_s", east]];
    private _i = [east, west, independent, civilian] findIf { _x isEqualTo _s };
    if (_i < 0) then { _i = 0 };
    ["EAST", "WEST", "INDEP", "CIV"] select _i
};

hds_fnc_factionsSideDepuisNom = {
    params [["_nom", "EAST"]];
    private _i = ["EAST", "WEST", "INDEP", "CIV"] findIf { _x isEqualTo (toUpper _nom) };
    if (_i < 0) then { _i = 0 };
    [east, west, independent, civilian] select _i
};

// ═══════════════════════════════════════════════════════════
// FONCTIONS
// ═══════════════════════════════════════════════════════════
hds_fnc_factionsClasserGroupe = compile preprocessFile "hdssystem\modules\factions\fncs\classer-groupe.sqf";
hds_fnc_factionsScanGroupes   = compile preprocessFile "hdssystem\modules\factions\fncs\scan-groupes.sqf";
hds_fnc_factionsScanVehicules = compile preprocessFile "hdssystem\modules\factions\fncs\scan-vehicules.sqf";
hds_fnc_factionsScanCivils    = compile preprocessFile "hdssystem\modules\factions\fncs\scan-civils.sqf";
hds_fnc_factionHommes         = compile preprocessFile "hdssystem\modules\factions\fncs\choisir-hommes.sqf";
hds_fnc_factionResoudre       = compile preprocessFile "hdssystem\modules\factions\fncs\resoudre.sqf";
hds_fnc_factionGroupes        = compile preprocessFile "hdssystem\modules\factions\fncs\choisir-groupes.sqf";
hds_fnc_factionGroupe         = compile preprocessFile "hdssystem\modules\factions\fncs\choisir-groupe.sqf";
hds_fnc_factionVehicules      = compile preprocessFile "hdssystem\modules\factions\fncs\choisir-vehicules.sqf";
hds_fnc_factionVehicule       = compile preprocessFile "hdssystem\modules\factions\fncs\choisir-vehicule.sqf";
hds_fnc_factionDuTerrain      = compile preprocessFile "hdssystem\modules\factions\fncs\faction-du-terrain.sqf";
hds_fnc_factionsListe         = compile preprocessFile "hdssystem\modules\factions\fncs\liste.sqf";
hds_fnc_factionsDump          = compile preprocessFile "hdssystem\modules\factions\fncs\dump.sqf";

// Export vers l'extérieur. Le pendant client, hds_fnc_factionsExportRecoit,
// est compilé dans mes-parametres.sqf : ce fichier-ci n'est chargé que par
// le serveur, et c'est le client qui doit remplir le presse-papier.
hds_fnc_factionsExport        = compile preprocessFile "hdssystem\modules\factions\fncs\export.sqf";
hds_fnc_factionsExportDemande = compile preprocessFile "hdssystem\modules\factions\fncs\export-demande.sqf";

// Le relief de la carte voyage avec le registre : meme bouton, meme
// collage. Le generateur peut donc dessiner la vraie carte du serveur
// sans rien demander de plus a l'utilisateur.
hds_fnc_terrainExport         = compile preprocessFile "hdssystem\modules\factions\fncs\export-terrain.sqf";

// ═══════════════════════════════════════════════════════════
// SCAN AU DÉMARRAGE — MODE D'EXÉCUTION
// ═══════════════════════════════════════════════════════════
// MESURÉ, pas supposé. Serveur avec CBA + RHS AFRF + USAF, 11585
// groupes et 17912 véhicules :
//
//   ordonnancé (spawn)   : 4426 ms, puis 4508 ms après optimisations
//   non ordonnancé (isNil):  963 ms  (groupes 627, véhicules 333)
//                            sur 1 image, canSuspend = false
//
// Les 4,5 s n'étaient donc pas du calcul : un script lancé avec spawn
// est ORDONNANCÉ et ne reçoit qu'environ 3 ms par image, si bien que
// ~1 s de travail s'étalait sur des centaines d'images. C'est aussi
// pourquoi des optimisations réelles (filtre déplacé dans le moteur,
// cache de 9530 classes, fin d'un pushBackUnique quadratique) ne
// changeaient rien au chrono : elles réduisaient le calcul, pas le
// nombre d'images nécessaires pour consommer le budget.
//
// On garde donc le mode bloquant par défaut : 963 ms pendant le
// chargement de la mission, là où l'écran est déjà figé, contre 4,5 s
// d'attente du registre. Et surtout, plus aucune course : tout est prêt
// avant que quoi que ce soit puisse demander une faction.
//
// Le levier reste accessible. Passer à false étale le scan sans gêner
// les images, ce qui peut devenir préférable si le serveur empile assez
// de mods pour que le bloquant dépasse 2 ou 3 secondes :
//   hds_factions_scan_bloquant = false;   // avant le chargement du module
//
// Les deux témoins (images parcourues, canSuspend) restent dans la
// ligne de journal : ils ne coûtent rien et c'est ce qui a permis de
// trancher au lieu d'optimiser à l'aveugle.
if (isNil "hds_factions_scan_bloquant") then { hds_factions_scan_bloquant = true };

// [ms groupes, ms vehicules, a tourne non ordonnance]
hds_factions_chrono = [0, 0, 0, false];

[] spawn {
    private _t0 = diag_tickTime;
    private _f0 = diag_frameNo;

    if (hds_factions_scan_bloquant) then {
        isNil {
            // canSuspend renseigné ici : c'est la preuve que isNil a bien
            // basculé en non ordonnancé, au lieu de me croire sur parole.
            private _a = diag_tickTime;
            call hds_fnc_factionsScanGroupes;
            private _b = diag_tickTime;
            call hds_fnc_factionsScanVehicules;
            private _c = diag_tickTime;
            call hds_fnc_factionsScanCivils;
            hds_factions_chrono = [
                round ((_b - _a) * 1000),
                round ((_c - _b) * 1000),
                round ((diag_tickTime - _c) * 1000),
                !canSuspend
            ];
            nil
        };
    } else {
        private _a = diag_tickTime;
        call hds_fnc_factionsScanGroupes;
        private _b = diag_tickTime;
        call hds_fnc_factionsScanVehicules;
        private _c = diag_tickTime;
        call hds_fnc_factionsScanCivils;
        hds_factions_chrono = [
            round ((_b - _a) * 1000),
            round ((_c - _b) * 1000),
            round ((diag_tickTime - _c) * 1000),
            !canSuspend
        ];
    };

    private _t2 = diag_tickTime;
    private _images = diag_frameNo - _f0;

    hds_factions_pret = true;
    publicVariable "hds_factions_pret";

    // Via le journal et non diag_log : comme ça la ligne se retrouve
    // dans le presse-papier avec « Copier le journal HDS », et pas
    // seulement au fond du RPT.
    // Les deux phases sont chronométrées séparément : sans ça, on ne
    // sait pas laquelle optimiser.
    ["INFO", "FACTIONS", format [
        "Scan termine en %1 ms (groupes %2, vehicules %3, civils %4) sur %5 image(s), non-ordonnance=%6 - %7 factions, %8 classes en cache",
        round ((_t2 - _t0) * 1000),
        hds_factions_chrono select 0,
        hds_factions_chrono select 1,
        hds_factions_chrono select 2,
        _images,
        hds_factions_chrono select 3,
        count hds_factions,
        count hds_factions_cache_genre
    ]] call hds_fnc_log;

    // Trace lisible + ligne compacte pour une interface externe
    call hds_fnc_factionsDump;
};
