/*
 * fnc_occupations_civil_init
 * ─────────────────────────────────────────────────────────────
 * Place une population civile dans une zone : des casaniers assis chez
 * eux, des piétons qui déambulent.
 *
 * 0 : <ARRAY>  position centrale
 * 1 : <NUMBER> densité ajoutée au nombre déduit des maisons
 * 2 : <NUMBER> rayon de la zone (m)
 * 3 : <STRING|NUMBER> population :
 *       "id"    un id de faction civile du registre, par exemple
 *               "CIV_F" ou "LOP_Tak_Civ". C'est la façon de choisir une
 *               population précise, et l'export du registre te donne la
 *               liste des ids réellement disponibles.
 *       nombre  accepté pour les anciens appels, mais sans effet : le
 *               registre choisit une faction civile du serveur.
 *       ""      idem
 * 4 : <BOOL>   marqueur visible sur la carte
 *
 * exemple : [[0,0,0], 0, 300, 0, false] call fnc_occupations_civil_init;
 *
 * ── Ce qui a changé ──
 * Les quatre blocs quasi identiques, un par nationalité, sont devenus
 * un seul : les classes viennent du registre de factions, plus de
 * listes codées en dur.
 *
 * Les anciennes nationalités 0 à 3 désignaient des listes de
 * classnames qui ont été retirées avec le reste. Un nombre est donc
 * encore accepté — les vieux appels ne cassent pas — mais il ne
 * sélectionne plus rien : le registre choisit. Pour une population
 * précise, on passe l'id de sa faction, que l'export du registre
 * fournit. Et si cette faction manque sur le serveur, le repli donne
 * des civils d'une autre faction du même camp plutôt que rien.
 *
 * ── Un bug corrigé au passage ──
 * Le bloc des européens finissait par « if (...) exitWith { ... } » à
 * l'intérieur de la boucle for : exitWith sortait de la BOUCLE, pas du
 * test. La nationalité 0 ne produisait donc jamais qu'un seul casanier
 * et un seul piéton, quelle que soit la densité demandée. Les trois
 * autres nationalités, qui utilisaient « then », bouclaient bien.
 */

params [
    ["_centre",          [0,0,0]],
    ["_ratio",           0],
    ["_taille",          300],
    ["_nationalite",     0],
    ["_marqueurvisible", false]
];

if (!isServer) exitWith {};

// Réglage « Population civile » du menu CBA : décoché, on ne place rien.
// Utile pour alléger un serveur chargé sans toucher au scénario.
if !(missionNamespace getVariable ["hds_civils_actifs", true]) exitWith {
    if (hdssysteme) then {
        diag_log "[HDS][CIVILS] Population civile desactivee par reglage";
    };
};

if (!hds_factions_pret) then {
    if (canSuspend) then { waitUntil { hds_factions_pret } };
};

// ─── Quelle population ? ───
// Une chaîne est un id de faction ; un nombre vient d'un ancien appel
// et laisse le registre décider.
private _idFaction = "";
if (_nationalite isEqualType "") then { _idFaction = _nationalite };

// Un id si on en a trouvé un, sinon le camp civil : le registre choisit
private _classes = [
    if (_idFaction != "") then { _idFaction } else { civilian }
] call hds_fnc_factionHommes;

if (_classes isEqualTo []) exitWith {
    ["ALERTE", "CIVILS", format [
        "Aucune classe de civil disponible (population demandee : %1)", _nationalite
    ]] call hds_fnc_log;
};

// ─── Marqueur de secteur ───
// Compteur et non nombre au hasard : deux zones finissaient par
// partager le même nom de marqueur.
if (isNil "hds_occups_civil_compteur") then { hds_occups_civil_compteur = 0 };
hds_occups_civil_compteur = hds_occups_civil_compteur + 1;

private _secteur = [
    format ["hds_occups_civil_%1", hds_occups_civil_compteur],
    _centre, "Ellipse", [_taille, _taille],
    "BRUSH:", "SolidBorder",
    "COLOR:", "colorCivilian"
] call cba_fnc_createMarker;

_secteur setMarkerAlpha 0;
// La mission peut demander ce marqueur pour elle-même : dans ce
// cas son alpha normal est 1 et le mode debug n'y change rien.
// Sinon c'est le debug seul qui le montre, et le décocher le fait
// disparaître dans la seconde.
[_secteur, ([0, 1] select (_marqueurvisible isEqualTo true))] call hds_fnc_debugMarqueur;

// ─── Combien d'habitants ───
private _places = [_taille, _centre, ["house"]] call fnc_objectif_liste_batimentsetplaces;
private _nbMaisons = if (count _places > 0) then { count (_places select 0) } else { 0 };
private _nb = round ((_nbMaisons / 3) + _ratio);
if (_nb < 1) then { _nb = 1 };

if (hdssysteme) then {
    ["INFO", "CIVILS", format [
        "%1 habitants autour de [%2,%3] - %4 classes, %5 maisons",
        _nb, round (_centre select 0), round (_centre select 1),
        count _classes, _nbMaisons
    ]] call hds_fnc_log;
};

// ─── Mise en place ───
for "_i" from 1 to _nb do {

    // Casanier : assis chez lui
    private _casanier = [_centre, 180, selectRandom _classes, civilian] call BIS_fnc_spawnVehicle;
    private _hommeC = _casanier select 0;
    if (!isNull _hommeC) then {
        [_centre, nil, [_hommeC], _taille, 1, false, true] call hds_fnc_garnison;
        [_hommeC, "SIT_LOW_U", "NONE"] call BIS_fnc_ambientAnim;
        _hommeC enableDynamicSimulation true;
    };

    // Piéton : il déambule dans le tiers central
    private _pieton = [_centre, 180, selectRandom _classes, civilian] call BIS_fnc_spawnVehicle;
    private _hommeP = _pieton select 0;
    if (!isNull _hommeP) then {
        [(_pieton select 2), _centre, (_taille / 3)] call BIS_fnc_taskPatrol;
        _hommeP enableDynamicSimulation true;
    };
};

true
