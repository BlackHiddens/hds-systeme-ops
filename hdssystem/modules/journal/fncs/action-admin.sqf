/*
 * hds_fnc_outilsAdminInit
 * ─────────────────────────────────────────────────────────────
 * Donne à l'administrateur un point d'entrée vers la fenêtre
 * « Outils admin ». Un seul, et pas trois dans la molette.
 *
 * Aucun paramètre. À appeler côté client, depuis initplayerlocal.sqf.
 *
 * ── Ce qui a changé, et pourquoi ──
 * Cette fonction posait trois addAction sur le joueur : copier le
 * journal, copier les erreurs, copier le registre. Trois défauts :
 *
 *   1. La molette est déjà encombrée — renforts, soins, arsenal,
 *      postes de communication. Trois entrées de debug par-dessus,
 *      c'était la fonction utile qu'on ne trouvait plus.
 *   2. Un addAction sur le joueur est visible par les joueurs autour
 *      de lui. Réservé aux admins, oui, mais pas discret.
 *   3. Les trois conditions étaient relues à chaque image.
 *
 * Tout est maintenant derrière la fenêtre, et la fenêtre derrière une
 * entrée du menu Échap. Celle du registre était en plus mal
 * conditionnée : « hds_factions_pret » n'existe que sur le serveur, où
 * le module factions est chargé, donc l'entrée restait invisible chez
 * tous les clients d'un serveur dédié — exactement ceux qui en avaient
 * besoin. La fenêtre l'affiche toujours : la demande part au serveur
 * par remoteExec, c'est lui qui a le registre.
 *
 * ── Trois voies d'accès ──
 * Menu Échap, raccourci clavier, et une action de molette en dernier
 * recours : si les deux appels CBA échouent, les outils restent
 * atteignables, et le journal dit laquelle a échoué.
 *
 * ── Signatures CBA ──
 * Lues dans les archives du mod installé (CBA 3.19.0), pas devinées :
 *
 *   CBA_fnc_addPauseMenuOption : [_name, _dialog]
 *     _name   <STRING ou [nom, infobulle]>
 *     _dialog <STRING> : le NOM DE CLASSE du dialogue a ouvrir.
 *
 * C'est là qu'était l'erreur au chargement : l'appel passait du code en
 * deuxième position. Arma signalait « Type code, Chaine attendu » puis
 * retenait la valeur par défaut, "". Le bouton apparaissait donc bien
 * dans le menu Échap, mais n'ouvrait rien.
 *
 * CBA ouvre le dialogue lui-même, sans passer par hds_fnc_outilsAdmin :
 * la vérification des droits se fait donc aussi dans le onLoad de
 * hds_outils_admin.
 */

if (!hasInterface) exitWith { false };

// ─── Qui a le droit ───
// Même règle que hds_fnc_outilsAdmin, qui la revérifiera de toute
// façon à l'ouverture : ici c'est pour ne pas afficher l'entrée du
// tout à quelqu'un qui n'y a pas droit.
private _liste = missionNamespace getVariable ["hds_administrateurs", []];
private _autorise = ((getPlayerUID player) in _liste) || { isServer && hasInterface };

if (!_autorise) exitWith { false };

private _voies = [];

// ─── 1. Menu Échap ───
private _menu = [
    {
        [
            ["HDS — Outils admin", "Copier le journal ou le registre des factions."],
            "hds_outils_admin"
        ] call CBA_fnc_addPauseMenuOption;
        true
    },
    "OUTILS",
    []
] call hds_fnc_proteger;

if (_menu select 0) then { _voies pushBack "menu Echap" };

// ─── 2. Raccourci clavier, sans touche par défaut ───
// Aucune touche assignée : on n'écrase rien chez personne. Elle se
// choisit dans Options → Contrôles → Addons, catégorie HDS.
private _touche = [
    {
        [
            "HDS",
            "hds_outils_admin",
            ["Outils admin", "Ouvre la fenêtre de copie du journal et du registre."],
            { [] call hds_fnc_outilsAdmin; true },
            {},
            [-1, [false, false, false]],
            false
        ] call CBA_fnc_addKeybind;
        true
    },
    "OUTILS",
    []
] call hds_fnc_proteger;

if (_touche select 0) then { _voies pushBack "raccourci clavier" };

// ─── 3. Dernier recours : une action de molette, une seule ───
if (_voies isEqualTo []) then {
    player addAction [
        "<t color='#00aaff'>HDS — Outils admin</t>",
        { [] call hds_fnc_outilsAdmin },
        nil, 1.5, false, true, "",
        "true", 5
    ];
    _voies pushBack "molette (repli)";

    ["ALERTE", "OUTILS",
     "les deux appels CBA ont echoue - repli sur une action de molette"
    ] call hds_fnc_log;
};

["INFO", "OUTILS", format [
    "outils admin accessibles pour %1 via : %2",
    name player, _voies joinString ", "
]] call hds_fnc_log;

true
