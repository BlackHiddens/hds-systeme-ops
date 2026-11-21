/*
 * hds_fnc_log
 * ─────────────────────────────────────────────────────────────
 * Écrit une ligne dans le RPT et dans le tampon mémoire.
 *
 * 0 : <STRING> niveau : "ERREUR" | "ALERTE" | "INFO" | "DEBUG"
 * 1 : <STRING> source, en majuscules court : "FACTIONS", "OCCUPATIONS"…
 * 2 : <STRING|ANY> message (converti avec str si ce n'est pas du texte)
 *
 * Retourne : <STRING> la ligne écrite, "" si filtrée par le seuil
 *
 * Format de ligne, pensé pour être grepable :
 *   [HDS][ERREUR][FACTIONS][DED][14:32:07][t=125] message
 *
 * Exemple :
 *   ["ERREUR", "FACTIONS", "registre vide apres le scan"] call hds_fnc_log;
 *   ["DEBUG", "OCCUPATIONS", format ["%1 groupes", count _g]] call hds_fnc_log;
 *
 * Une ERREUR émise par le serveur est renvoyée à tous les clients, pour
 * qu'un admin récupère serveur + local d'un seul coup de presse-papier.
 */

params [["_niveau", "INFO"], ["_source", "HDS"], ["_message", ""]];

private _n = toUpper _niveau;
private _iNiveau = hds_journal_niveaux findIf { _x isEqualTo _n };
if (_iNiveau < 0) then { _iNiveau = 2; _n = "INFO" };

private _iSeuil = hds_journal_niveaux findIf { _x isEqualTo hds_journal_seuil };
if (_iSeuil < 0) then { _iSeuil = 2 };

// Au-dessus du seuil : on ne garde pas
if (_iNiveau > _iSeuil) exitWith { "" };

if !(_message isEqualType "") then { _message = str _message };

// ─── Horodatage ───
// systemTime donne l'heure réelle, time la seconde de mission :
// la première situe l'erreur dans tes logs, la seconde dans la partie.
//
// Le remplissage à deux chiffres est fait à la main : BIS_fnc_numberPadded
// n'existe pas. Je l'avais utilisé de mémoire, et c'est le deuxième bug
// qu'a remonté la première exécution.
private _pad = { if (_this < 10) then { "0" + str _this } else { str _this } };

private _h = "??:??:??";
private _st = systemTime;
if (count _st >= 6) then {
    _h = format ["%1:%2:%3",
        (_st select 3) call _pad,
        (_st select 4) call _pad,
        (_st select 5) call _pad
    ];
};

private _ligne = format ["[HDS][%1][%2][%3][%4][t=%5] %6",
    _n, toUpper _source, hds_journal_machine, _h, round time, _message];

// ─── RPT ───
diag_log _ligne;

// ─── Tampon mémoire ───
hds_journal pushBack _ligne;
if (count hds_journal > hds_journal_max) then {
    hds_journal deleteAt 0;
};

if (_n isEqualTo "ERREUR") then { hds_journal_erreurs = hds_journal_erreurs + 1 };
if (_n isEqualTo "ALERTE") then { hds_journal_alertes = hds_journal_alertes + 1 };

// ─── Les erreurs serveur descendent vers les clients ───
// Les erreurs sont rares : le coût réseau est négligeable, et ça permet
// à un admin d'avoir le journal serveur dans son presse-papier.
if (_n isEqualTo "ERREUR" && { isServer } && { !isNil "hds_fnc_journalRecevoir" }) then {
    [_ligne] remoteExec ["hds_fnc_journalRecevoir", -2];
};

_ligne
