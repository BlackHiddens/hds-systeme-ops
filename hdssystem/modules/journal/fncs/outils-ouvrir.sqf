/*
 * hds_fnc_outilsAdmin
 * ─────────────────────────────────────────────────────────────
 * Ouvre la fenêtre « Outils admin » (hdssystem\ui\hds-outils-admin.hpp),
 * après avoir vérifié que celui qui demande a le droit.
 *
 * Aucun paramètre. Retourne <BOOL> : true si la fenêtre s'est ouverte.
 *
 * ── Qui est administrateur ──
 * Deux cas, et deux seulement :
 *
 *   1. Son identifiant Steam est dans hds_administrateurs
 *      (mes-parametres.sqf). C'est un steamID64 : 17 chiffres, celui
 *      qu'on lit dans l'URL de son profil Steam, ou en jeu avec
 *      « copyToClipboard getPlayerUID player » dans la console de debug.
 *
 *   2. Il héberge la partie lui-même (isServer && hasInterface) :
 *      aperçu d'éditeur, serveur local. Celui qui fait tourner la
 *      mission sur sa machine n'a pas à s'inscrire dans sa propre
 *      liste pour tester, et sur un serveur dédié ce cas ne se
 *      présente jamais — la machine n'a pas d'interface.
 *
 * Même logique que hdssysteme : ce qui vaut pour « je teste chez moi »
 * se déduit, ce qui vaut en ligne s'écrit.
 */

if (!hasInterface) exitWith { false };

private _liste = missionNamespace getVariable ["hds_administrateurs", []];
private _autorise = ((getPlayerUID player) in _liste) || { isServer && hasInterface };

if (!_autorise) exitWith {
    hint parseText "<t color='#ff8844'>Outils HDS</t><br/><t size='0.85'>Réservés aux administrateurs.</t>";
    ["ALERTE", "OUTILS", format [
        "%1 (%2) a demande les outils admin sans y avoir droit",
        name player, getPlayerUID player
    ]] call hds_fnc_log;
    false
};

// Déjà ouverte : on ne l'empile pas, on rafraîchit.
if (!isNull (findDisplay 70101)) exitWith {
    [] call hds_fnc_outilsEtat;
    true
};

private _ok = createDialog "hds_outils_admin";

if (!_ok) then {
    // Arrive si l'include manque dans description.ext : on le dit en
    // clair plutôt que de laisser un clic sans effet.
    ["ERREUR", "OUTILS",
     "createDialog a echoue - verifier l'include de hdssystem\ui\hds-outils-admin.hpp dans description.ext"
    ] call hds_fnc_log;
    hint parseText "<t color='#ff4444'>Outils HDS</t><br/><t size='0.85'>La fenêtre n'a pas pu s'ouvrir. Voir le journal.</t>";
};

_ok
