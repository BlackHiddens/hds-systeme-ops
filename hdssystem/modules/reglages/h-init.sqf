/*
 * hdssystem\modules\reglages\h-init.sqf
 * ─────────────────────────────────────────────────────────────
 * HDS — Réglages en jeu, via le menu de CBA
 *
 * Chaque réglage apparaît dans Échap → Options → Options des addons,
 * catégorie « HDS ». Aucun dialogue à écrire : CBA construit l'interface,
 * la persiste, et gère les permissions serveur.
 *
 * ── Règle que je me suis fixée ──
 * Un réglage n'est ajouté que s'il a un point de branchement réel. Pas
 * de bouton qui ne fait rien. Les cinq ci-dessous agissent tous sur du
 * code existant, et le commentaire de chacun dit où.
 *
 * ── Pourquoi pas la liste des 205 factions ──
 * Un réglage CBA doit être déclaré à l'identique sur toutes les
 * machines. Or le registre n'existe que sur le serveur : les clients ne
 * pourraient pas construire la même liste sans qu'on la leur diffuse
 * d'abord, et une liste déroulante qui diverge entre machines casse le
 * menu. On s'en tient donc aux huit index d'origine, qui sont les mêmes
 * partout, plus « AUTO ». Le choix fin d'une faction se fait déjà là où
 * le registre est connu : dans le générateur, après import.
 *
 * ── Prudence sur l'API ──
 * Je n'ai pas pu vérifier la signature de CBA_fnc_addSetting dans la
 * documentation (le wiki Bohemia est derrière un contrôle anti-robot).
 * Chaque appel passe donc par hds_fnc_proteger : si la signature a
 * changé, on récupère une ligne d'erreur lisible dans le journal au
 * lieu d'un module mort, et les valeurs de mes-parametres.sqf
 * continuent de s'appliquer.
 *
 * Inclus depuis mes-parametres.sqf, après le journal : chargé des deux
 * côtés, ce qui est nécessaire pour que le menu existe chez les clients.
 */

// Vrai une fois que CBA a repris la main sur les valeurs
hds_reglages_actifs = false;

private _poser = {
    params ["_nom", "_type", "_titre", "_valeurs", "_global", "_script", "_redemarrage"];
    [
        {
            params ["_nom", "_type", "_titre", "_valeurs", "_global", "_script", "_redemarrage"];
            [_nom, _type, _titre, "HDS", _valeurs, _global, _script, _redemarrage] call CBA_fnc_addSetting;
            true
        },
        "REGLAGES",
        [_nom, _type, _titre, _valeurs, _global, _script, _redemarrage]
    ] call hds_fnc_proteger
};

// ═══════════════════════════════════════════════════════════
// 1. Mode debug  →  hdssysteme
// ═══════════════════════════════════════════════════════════
// Lu partout : traces dans le RPT, marqueurs de zone visibles,
// messages systemChat, dump du registre.
[
    "hds_debug", "CHECKBOX",
    ["Mode debug", "Traces dans le RPT, marqueurs de zone visibles, messages en chat."],
    hdssysteme, 1,
    { params ["_v"]; hdssysteme = _v; if (!isNil "hds_fnc_debugAppliquer") then { [] call hds_fnc_debugAppliquer }; },
    false
] call _poser;

// ═══════════════════════════════════════════════════════════
// 2. Niveau du journal  →  hds_journal_seuil
// ═══════════════════════════════════════════════════════════
// Lu par hds_fnc_log à chaque ligne : tout ce qui est moins grave que
// le seuil n'est ni écrit ni mis en tampon.
[
    "hds_journal_niveau", "LIST",
    ["Niveau du journal", "Ce qui est gardé dans le RPT et dans le presse-papier."],
    [["ERREUR", "ALERTE", "INFO", "DEBUG"],
     ["Erreurs seules", "Erreurs et alertes", "Informations", "Tout"],
     2],
    1,
    { params ["_v"]; hds_journal_seuil = _v; },
    false
] call _poser;

// ═══════════════════════════════════════════════════════════
// 3. Scan bloquant  →  hds_factions_scan_bloquant
// ═══════════════════════════════════════════════════════════
// Lu une seule fois, au démarrage du module factions : d'où le drapeau
// « redémarrage nécessaire » à true, que CBA affiche dans le menu.
// Mesuré : bloquant 963 ms sur une image, ordonnancé 4508 ms étalées.
[
    "hds_scan_bloquant", "CHECKBOX",
    ["Scan des factions bloquant", "Coché : ~1 s de gel au chargement, registre prêt tout de suite. Décoché : étalé sur plusieurs secondes, sans gel."],
    true, 1,
    { params ["_v"]; hds_factions_scan_bloquant = _v; },
    true
] call _poser;

// ═══════════════════════════════════════════════════════════
// 4. Faction forcée  →  hds_fnc_factionDuTerrain
// ═══════════════════════════════════════════════════════════
// AUTO laisse le système déduire la faction de ce qui est posé dans
// l'éditeur. Un index force ce camp-là, et seulement lui : demander un
// renfort BLUFOR pendant que l'OPFOR est forcé en RHS reste cohérent.
[
    "hds_faction_forcee", "LIST",
    ["Faction forcée", "AUTO déduit la faction de ce que la mission a posé dans l'éditeur. Un choix ne s'applique qu'à son propre camp."],
    [["AUTO", "0", "1", "2", "3", "4", "5", "6", "7"],
     ["Déduite de l'éditeur", "CSAT", "AAF", "Américains", "FIA",
      "Boko Haram", "Russes (RHS)", "Afghans", "État islamique"],
     0],
    1,
    { params ["_v"]; hds_faction_forcee = _v; },
    false
] call _poser;

// ═══════════════════════════════════════════════════════════
// 5. Population civile  →  fnc_occupations_civil_init
// ═══════════════════════════════════════════════════════════
// Décoché, la fonction sort immédiatement : utile pour alléger un
// serveur chargé sans toucher au scénario.
[
    "hds_civils", "CHECKBOX",
    ["Population civile", "Décoché : les occupations ne placent aucun civil."],
    true, 1,
    { params ["_v"]; hds_civils_actifs = _v; },
    false
] call _poser;

// ══════════════════════════════════════════════════════════
// 6. Densité du trafic civil  →  hds_civils_densite
// ══════════════════════════════════════════════════════════
// Relu à chaque cycle par fnc_hds_vie_civile : le changement prend
// effet en huit secondes, sans relancer la mission. C'est le nombre de
// véhicules entretenus AUTOUR des joueurs, pas sur toute la carte —
// l'ancien VEHICLES_COUNT d'Engima valait 5.
[
    "hds_civils_densite", "SLIDER",
    ["Densité du trafic civil", "Nombre de véhicules civils entretenus autour des joueurs. 0 : plus de trafic, mais les habitants restent."],
    [0, 30, 8, 0],
    1,
    { params ["_v"]; hds_civils_densite = _v; },
    false
] call _poser;

// ─── Valeurs de repli ───
// Si CBA n'a pas pris la main (API changée, réglage non encore reçu),
// ces variables doivent exister quand même : tout le code qui les lit
// passe par getVariable avec défaut, mais autant être explicite.
if (isNil "hds_faction_forcee") then { hds_faction_forcee = "AUTO" };
if (isNil "hds_civils_actifs")  then { hds_civils_actifs = true };
if (isNil "hds_civils_densite") then { hds_civils_densite = 8 };

hds_reglages_actifs = true;

diag_log format [
    "[HDS][REGLAGES] Menu CBA pose - debug:%1 seuil:%2 civils:%3 faction:%4",
    hdssysteme, hds_journal_seuil, hds_civils_actifs, hds_faction_forcee
];
