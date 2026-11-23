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
    ["_ratio",           -1],
    ["_taille",          300],
    ["_nationalite",     0],
    ["_marqueurvisible", false]
];

// ─── Pourquoi -1 et plus 0 ───
// 0 voulait dire « n'ajoute rien au nombre déduit des maisons ». Pour
// un paramètre de densité, c'est le plus mauvais défaut possible :
// appelée sans argument, la fonction donnait sa population la plus
// maigre — et dans un lieu sans maison, exactement un habitant.
//
// -1 veut maintenant dire « sers-toi du réglage », c'est-à-dire du
// curseur « Densité » du menu CBA. Un 0 explicite reste un 0 : quand
// fnc_hds_vie_civile calcule un supplément nul pour la rase campagne,
// c'est bien ce qu'il veut.
if (_ratio < 0) then {
    _ratio = round ((missionNamespace getVariable ["hds_civils_densite", 8]) / 2);
};

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

// ═══════════════════════════════════════════════════════════
// MISE EN PLACE
// ═══════════════════════════════════════════════════════════
// ── Pourquoi plus de BIS_fnc_spawnVehicle ──
// Elle servait à faire naître les deux civils. C'est une fonction à
// véhicules : donnée une classe d'homme, ce qu'elle rend en troisième
// position n'est pas un groupe exploitable. BIS_fnc_taskPatrol le
// recevait quand même, ne faisait rien, et le piéton restait planté là
// où il était tombé — souvent à l'intérieur d'un mur, au centre exact
// de la zone. D'où l'impression qu'il n'y avait aucun piéton.
//
// createGroup + createUnit, c'est la façon d'en créer : le groupe est
// réel, la patrouille fonctionne, et l'homme marche.

// Un seul groupe pour les casaniers : ils ne bougent pas, inutile d'en
// faire un par personne. Les piétons, eux, en ont chacun un, sans quoi
// ils déambuleraient en formation comme une escouade.
private _grpMaison = createGroup [civilian, true];

private _fnCreer = {
    params ["_grp", "_cls", "_pos"];
    private _avant = units _grp;
    _grp createUnit [_cls, _pos, [], 0, "NONE"];
    private _neufs = (units _grp) - _avant;
    if (_neufs isEqualTo []) then { objNull } else { _neufs select 0 }
};

// Une position au hasard dans la zone.
private _fnQuelquePart = {
    params ["_rayon"];
    private _a = random 360;
    private _d = sqrt (random 1) * _rayon;
    [(_centre select 0) + _d * sin _a, (_centre select 1) + _d * cos _a, 0]
};

// Les routes de l'agglomération : un piéton se voit sur un trottoir,
// pas au fond d'un jardin.
private _routes = _centre nearRoads _taille;

private _poses = 0;
private _dernierPieton = objNull;

for "_i" from 1 to _nb do {

    // ─── Casanier : assis chez lui ───
    private _hommeC = [_grpMaison, selectRandom _classes, [_taille] call _fnQuelquePart]
        call _fnCreer;

    if (!isNull _hommeC) then {
        [_centre, nil, [_hommeC], _taille, 1, false, true] call hds_fnc_garnison;
        [_hommeC, "SIT_LOW_U", "NONE"] call BIS_fnc_ambientAnim;
        _hommeC enableDynamicSimulation true;

        // Civil d'ambiance : fnc_hds_vie_civile le retirera quand plus
        // aucun joueur ne sera assez près pour le voir. La marque est
        // ce qui le distingue d'un otage ou d'un VIP posé par une
        // mission, qui ne doit jamais être balayé.
        _hommeC setVariable ["hds_civil_ambiance", true, true];
        _poses = _poses + 1;
    };

    // ─── Piéton : il déambule, et on le voit ───
    private _depart = if (_routes isEqualTo []) then {
        [_taille] call _fnQuelquePart
    } else {
        getPos (selectRandom _routes)
    };

    private _grpP = createGroup [civilian, true];
    private _hommeP = [_grpP, selectRandom _classes, _depart] call _fnCreer;

    if (isNull _hommeP) then {
        deleteGroup _grpP;
    } else {
        _hommeP setPosATL _depart;

        [_grpP, _centre, (_taille * 0.6), 4] call BIS_fnc_taskPatrol;
        _grpP setBehaviour "CARELESS";
        _grpP setSpeedMode "LIMITED";

        // Pas de simulation dynamique sur un pieton d'ambiance : il
        // est deja supprime des qu'il s'eloigne, le geler en plus ne
        // fait qu'ajouter une facon de le voir immobile.
        _hommeP setVariable ["hds_civil_ambiance", true, true];
        _dernierPieton = _hommeP;
        _poses = _poses + 1;
    };
};

// ─── De quoi trancher au prochain essai ───
// « Je ne croise aucun piéton » peut vouloir dire trois choses : ils
// n'existent pas, ils existent mais n'ont pas d'itinéraire, ou ils en
// ont un mais la simulation est coupée. On relève les trois sur le
// dernier piéton créé plutôt que de continuer à deviner.
if (!isNull _dernierPieton) then {
    private _grpP = group _dernierPieton;

    ["INFO", "CIVILS", format [
        "temoin pieton : %1 waypoint(s), simulation %2, comportement %3, a %4 m du centre",
        count (waypoints _grpP),
        ["COUPEE", "active"] select (simulationEnabled _dernierPieton),
        behaviour _dernierPieton,
        round (_dernierPieton distance2D _centre)
    ]] call hds_fnc_log;
};

["INFO", "CIVILS", format [
    "%1 civil(s) places sur %2 voulus autour de [%3,%4] - %5 route(s) dans la zone",
    _poses, _nb * 2,
    round (_centre select 0), round (_centre select 1),
    count _routes
]] call hds_fnc_log;

true
