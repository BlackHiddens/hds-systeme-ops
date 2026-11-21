/*
 * hdssystem\modules\journal\h-init.sqf
 * ─────────────────────────────────────────────────────────────
 * HDS — Journal d'exécution
 *
 * But : pouvoir copier-coller un rapport d'erreurs au lieu de le
 * décrire ou d'en faire une capture d'écran.
 *
 * ── Ce qu'il faut savoir d'abord ──
 * Le SQF ne peut pas écrire de fichier. Le seul fichier que le jeu
 * produit, c'est son RPT :
 *   %LOCALAPPDATA%\Arma 3\Arma3_x64_<date>.rpt
 * Tout ce qui passe par diag_log y atterrit. Ce module fait donc
 * deux choses :
 *
 *   1. écrire des lignes propres, préfixées et filtrables dans le RPT
 *      → à extraire ensuite avec outils\extraire-log.ps1, qui produit
 *        un petit fichier lisible (ça, c'est le fichier à coller)
 *
 *   2. garder les dernières entrées en mémoire, pour les copier dans
 *      le presse-papier depuis le jeu, sans toucher au RPT
 *      → hds_fnc_journalCopier, ou l'action admin « Copier le journal »
 *
 * Les erreurs du serveur sont renvoyées aux clients, pour qu'un admin
 * ait serveur + local dans le même presse-papier.
 *
 * Inclus depuis mes-parametres.sqf : chargé serveur ET client, chaque
 * machine journalisant ses propres erreurs.
 */

// ═══════════════════════════════════════════════════════════
// NIVEAUX
// ═══════════════════════════════════════════════════════════
// Plus le chiffre est petit, plus c'est grave.
hds_journal_niveaux = ["ERREUR", "ALERTE", "INFO", "DEBUG"];

// Seuil : en debug on garde tout, sinon on s'arrête à INFO.
hds_journal_seuil = ["INFO", "DEBUG"] select (hdssysteme isEqualTo true);

// ═══════════════════════════════════════════════════════════
// TAMPON CIRCULAIRE
// ═══════════════════════════════════════════════════════════
if (isNil "hds_journal")          then { hds_journal = [] };
if (isNil "hds_journal_erreurs")  then { hds_journal_erreurs = 0 };
if (isNil "hds_journal_alertes")  then { hds_journal_alertes = 0 };
hds_journal_max = 300;

// Garde-fou anti-boucle : si la journalisation elle-même échoue dans
// le handler d'erreur, on ne veut pas d'une erreur qui s'auto-nourrit.
if (isNil "hds_journal_dans_eh") then { hds_journal_dans_eh = false };

// Étiquette de machine, pour savoir d'où vient une ligne
hds_journal_machine = if (isDedicated) then { "DED" } else {
    if (isServer) then { "HOST" } else { "CLI" }
};

// ═══════════════════════════════════════════════════════════
// FONCTIONS
// ═══════════════════════════════════════════════════════════
hds_fnc_log               = compile preprocessFile "hdssystem\modules\journal\fncs\log.sqf";
hds_fnc_proteger          = compile preprocessFile "hdssystem\modules\journal\fncs\proteger.sqf";
hds_fnc_journalRapport    = compile preprocessFile "hdssystem\modules\journal\fncs\rapport.sqf";
hds_fnc_journalCopier     = compile preprocessFile "hdssystem\modules\journal\fncs\copier.sqf";
hds_fnc_journalRecevoir   = compile preprocessFile "hdssystem\modules\journal\fncs\recevoir.sqf";

// ─── Fenêtre « Outils admin » ───
// Remplace les trois actions de molette. La classe de dialogue est
// dans hdssystem\ui\hds-outils-admin.hpp, incluse par description.ext.
hds_fnc_outilsAdminInit   = compile preprocessFile "hdssystem\modules\journal\fncs\action-admin.sqf";
hds_fnc_outilsAdmin       = compile preprocessFile "hdssystem\modules\journal\fncs\outils-ouvrir.sqf";
hds_fnc_outilsEtat        = compile preprocessFile "hdssystem\modules\journal\fncs\outils-etat.sqf";

// ═══════════════════════════════════════════════════════════
// CAPTURE DES ERREURS D'EXÉCUTION
// ═══════════════════════════════════════════════════════════
// SIGNATURE DE "ScriptError", relevée sur le terrain
//
// Le wiki Bohemia est derrière un contrôle anti-robot, donc la première
// version de ce handler journalisait le tableau brut indexé, sans rien
// supposer. Deux exécutions concordantes sur Arma 2.22 donnent :
//
//   [0] <STRING> le message d'erreur
//   [1] <STRING> vide dans les deux relevés
//   [2] <NUMBER> ligne fautive DANS le script concerné
//   [3] <NUMBER> offset en caractères
//   [4] <STRING> le source complet du script fautif
//   [5] <ARRAY>  la pile d'appels, du plus externe au plus interne :
//                [[fichier, ligne, "", [[nomVariable, valeur], ...]], ...]
//
// Le champ [4] et les variables locales de [5] représentaient à eux
// seuls des milliers de caractères par erreur : un rapport de 7 erreurs
// devenait illisible. On n'en garde donc que fichier:ligne, et le source
// complet part dans le RPT seulement, en mode debug.
//
// L'accès reste défensif (param avec valeurs par défaut) : si une mise à
// jour du jeu change la forme, on dégrade au lieu de casser. Et si
// l'event handler n'existe pas, le try l'avale et le module reste
// utilisable via hds_fnc_log et hds_fnc_proteger.
if (isNil "hds_journal_eh_pose") then {
    hds_journal_eh_pose = false;
};

if (!hds_journal_eh_pose) then {
    private _pose = {
        addMissionEventHandler ["ScriptError", {
            // Anti-réentrance : une erreur dans la journalisation ne doit
            // pas se nourrir d'elle-même.
            if (hds_journal_dans_eh) exitWith {};
            hds_journal_dans_eh = true;

            _this params [
                ["_msg",    "erreur sans message"],
                ["_vide",   ""],
                ["_ligne",  -1],
                ["_offset", -1],
                ["_src",    ""],
                ["_pile",   []]
            ];

            // Pile compacte : fichier:ligne, sans les variables locales
            private _trace = [];
            {
                if (_x isEqualType []) then {
                    private _f = _x param [0, ""];
                    private _n = _x param [1, -1];
                    if (_f isEqualTo "") then {
                        _f = "<compile>";
                    } else {
                        private _bouts = _f splitString "\/";
                        if (count _bouts > 0) then { _f = _bouts select ((count _bouts) - 1) };
                    };
                    _trace pushBack format ["%1:%2", _f, _n];
                };
            } forEach _pile;

            // Du plus interne au plus externe : l'erreur d'abord
            reverse _trace;

            ["ERREUR", "SQF", format ["%1 | ligne %2 (offset %3) | pile: %4",
                _msg, _ligne, _offset,
                (["pile vide", _trace joinString " <- "] select (count _trace > 0))
            ]] call hds_fnc_log;

            // Le source fautif ne va que dans le RPT, et seulement en debug
            if (hdssysteme && { _src != "" }) then {
                diag_log format ["[HDS][JOURNAL][SRC] ----- source fautif (ligne %1) -----", _ligne];
                diag_log _src;
                diag_log "[HDS][JOURNAL][SRC] -----------------------------------------";
            };

            hds_journal_dans_eh = false;
        }];
        true
    };

    private _ok = false;
    try { _ok = call _pose } catch { _ok = false };

    hds_journal_eh_pose = _ok;

    if (_ok) then {
        diag_log format ["[HDS][JOURNAL][%1] Capture ScriptError active", hds_journal_machine];
    } else {
        diag_log format [
            "[HDS][JOURNAL][%1] ScriptError indisponible - journalisation manuelle uniquement",
            hds_journal_machine
        ];
    };
};

diag_log format [
    "[HDS][JOURNAL][%1] Pret - seuil %2, tampon %3 lignes",
    hds_journal_machine, hds_journal_seuil, hds_journal_max
];
