/*
 * hds_fnc_journalRecevoir
 * ─────────────────────────────────────────────────────────────
 * Reçoit une ligne de journal venue d'une autre machine (en pratique :
 * une erreur serveur renvoyée aux clients) et l'ajoute au tampon local.
 *
 * 0 : <STRING> la ligne déjà formatée
 *
 * Cible de remoteExec depuis hds_fnc_log. Ne rediffuse rien : sinon
 * deux machines se renverraient la même ligne indéfiniment.
 */

params [["_ligne", ""]];

if (_ligne isEqualTo "") exitWith { false };

// Marquée comme distante, pour qu'on sache en lisant le rapport que
// cette ligne ne vient pas de la machine qui l'affiche.
private _marquee = "(distant) " + _ligne;

hds_journal pushBack _marquee;
if (count hds_journal > hds_journal_max) then {
    hds_journal deleteAt 0;
};

if ((_ligne find "[ERREUR]") > -1) then {
    hds_journal_erreurs = hds_journal_erreurs + 1;
};

true
