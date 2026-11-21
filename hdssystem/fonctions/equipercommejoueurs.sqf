/*
 * fnc_hds_equiperCommeJoueurs
 * ─────────────────────────────────────────────────────────────
 * Habille des unités d'après l'équipement que portent les joueurs.
 *
 * 0 : <ARRAY|GROUP|OBJECT> unités à équiper
 * 1 : <SIDE>               camp dont on copie l'équipement (défaut west)
 *
 * Retourne : <NUMBER> nombre d'unités réellement rhabillées
 *
 * ── Pourquoi ──
 * Les renforts alliés étaient habillés pièce par pièce : environ 195
 * classnames RHS et LOP écrits à la main, répartis sur 28 fichiers de
 * roster, un par rôle et par camouflage. Tout ça pour que les renforts
 * soient reconnaissables — ce que l'équipement des joueurs dit déjà.
 *
 * On copie donc leur tenue. Aucun classname en dur, et ça marche avec
 * n'importe quel mod puisque getUnitLoadout ne manipule que des
 * classnames, quels qu'ils soient. Le mod des joueurs devient la
 * référence, sans qu'on ait à le connaître.
 *
 * ── Comment ──
 * On préfère le joueur qui a le même typeOf que l'unité à habiller, de
 * façon qu'un mitrailleur ressemble au mitrailleur de l'équipe. À
 * défaut, un joueur au hasard.
 *
 * S'il n'y a personne à imiter, on ne touche à rien : l'unité garde
 * l'équipement de sa faction, qui est déjà cohérent puisqu'elle vient
 * du registre.
 *
 * ── Réserve ──
 * getUnitLoadout rend l'état COURANT, chargeurs entamés compris. Un
 * renfort peut donc arriver avec des chargeurs à moitié vides si les
 * joueurs ont déjà combattu. C'est le prix de « s'inspirer de ce qu'ils
 * portent maintenant » plutôt que d'un instantané pris au départ.
 *
 * À appeler côté SERVEUR, là où les unités IA sont locales.
 *
 * Exemple :
 *   [_groupe, west] call fnc_hds_equiperCommeJoueurs;
 */

params [["_cibles", []], ["_camp", west]];

// ─── Normalisation de l'entrée ───
if (_cibles isEqualType grpNull) then { _cibles = units _cibles };
if (_cibles isEqualType objNull) then { _cibles = [_cibles] };
if (!(_cibles isEqualType [])) exitWith { 0 };

_cibles = _cibles select { !isNull _x && { alive _x } };
if (_cibles isEqualTo []) exitWith { 0 };

// ─── Tenues disponibles chez les joueurs du camp ───
private _pool = [];
{
    private _l = getUnitLoadout _x;
    if (!(_l isEqualTo [])) then { _pool pushBack [typeOf _x, _l] };
} forEach (allPlayers select { alive _x && { (side _x) isEqualTo _camp } });

if (_pool isEqualTo []) exitWith {
    ["INFO", "EQUIPEMENT", "Aucun joueur a imiter - equipement de faction conserve"] call hds_fnc_log;
    0
};

// ─── Application ───
private _n = 0;
{
    private _unite = _x;
    private _t = typeOf _unite;

    private _i = _pool findIf { (_x select 0) isEqualTo _t };
    private _choix = if (_i >= 0) then { _pool select _i } else { selectRandom _pool };

    _unite setUnitLoadout (_choix select 1);
    _n = _n + 1;
} forEach _cibles;

["INFO", "EQUIPEMENT", format [
    "%1 unite(s) habillee(s) d'apres %2 tenue(s) de joueur", _n, count _pool
]] call hds_fnc_log;

_n
