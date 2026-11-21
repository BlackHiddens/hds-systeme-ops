/*
 * hdssystem\debug-mode.sqf
 * ─────────────────────────────────────────────────────────────
 * HDS — Rendre le mode debug réversible à la seconde
 *
 * Inclus depuis mes-parametres.sqf, avant le module des réglages :
 * chargé serveur ET client.
 *
 * ── Le problème ──
 * Les quatre-vingt-douze « if (hdssysteme) » du système se relisent à
 * chaque passage : décocher la case les éteint tout de suite, sans
 * rien à faire. Deux choses échappaient à cette règle, parce qu'elles
 * laissent une trace à l'écran au lieu de se contenter de tester :
 *
 *   1. l'alpha des marqueurs. « if (hdssysteme) then { _m setMarkerAlpha
 *      1 } » s'exécute une fois, à la création de l'objectif ou de la
 *      zone d'occupation. Les cercles rouges restaient donc visibles
 *      pour toute la partie, même case décochée ;
 *   2. les marqueurs d'ennemis de debug-carte.sqf, redessinés toutes
 *      les trente secondes — jusqu'à une demi-minute de retard ;
 *   3. la destination des tâches. Les dix objectifs appelaient
 *      BIS_fnc_taskCreate avec une position en debug et objNull
 *      autrement : une tâche créée case cochée gardait son repère sur
 *      la carte pour le reste de la partie.
 *
 * ── Ce que ce fichier apporte ──
 * hds_fnc_debugMarqueur et hds_fnc_debugTache remplacent le « if » :
 * ils appliquent l'état tout de suite ET retiennent de quoi revenir en
 * arrière. hds_fnc_debugAppliquer rejoue l'état sur les deux registres,
 * et c'est le réglage CBA qui l'appelle quand la case change.
 *
 * debug-carte.sqf, lui, relit l'état toutes les demi-secondes.
 *
 * ── Note multijoueur ──
 * setMarkerAlpha est à effet global : il ne doit partir que d'une
 * machine. Le registre n'est rempli que là où les marqueurs sont
 * créés, c'est-à-dire sur le serveur ; chez les clients il reste vide
 * et la fonction ne diffuse rien. Les marqueurs locaux de la carte de
 * debug sont gérés à part, par debug-carte.sqf.
 */

// Registres : [marqueur, alpha hors debug] et [tâche, position de debug]
if (isNil "hds_debug_marqueurs") then { hds_debug_marqueurs = [] };
if (isNil "hds_debug_taches")    then { hds_debug_taches = [] };

// Opacité des formes que le debug allume. Réglable depuis
// mes-parametres.sqf ; à 1, les cercles de secteur noircissent la
// carte et cachent le terrain qu'on cherche justement à lire.
if (isNil "hds_debug_alpha") then { hds_debug_alpha = 0.3 };

// L'opacité à appliquer à un marqueur : celle du debug, mais jamais
// moins que celle que la mission a demandée pour lui.
hds_fnc_debugOpacite = {
    params [["_alphaNormal", 0, [0]]];
    _alphaNormal max hds_debug_alpha
};

// ═══════════════════════════════════════════════════════════
// hds_fnc_debugMarqueur
// ═══════════════════════════════════════════════════════════
// [_marqueur, _alphaNormal] call hds_fnc_debugMarqueur
//
//   _marqueur    <STRING> le marqueur concerné
//   _alphaNormal <NUMBER> son alpha quand le debug est éteint
//
// Retourne <BOOL> : vrai si le marqueur a été pris en compte.
//
// À utiliser partout où on écrivait :
//     _m setMarkerAlpha 0;
//     if (hdssysteme) then { _m setMarkerAlpha 1 };
// qui devient :
//     [_m, 0] call hds_fnc_debugMarqueur;
hds_fnc_debugMarqueur = {
    params [["_marqueur", "", [""]], ["_alphaNormal", 0, [0]]];

    if (_marqueur isEqualTo "") exitWith { false };

    private _i = hds_debug_marqueurs findIf { (_x select 0) isEqualTo _marqueur };
    if (_i < 0) then {
        hds_debug_marqueurs pushBack [_marqueur, _alphaNormal];
    } else {
        // Même marqueur réutilisé : on garde la dernière consigne
        hds_debug_marqueurs set [_i, [_marqueur, _alphaNormal]];
    };

    _marqueur setMarkerAlpha (
        [_alphaNormal, ([_alphaNormal] call hds_fnc_debugOpacite)]
            select (hdssysteme isEqualTo true)
    );

    true
};

// ═══════════════════════════════════════════════════════════
// hds_fnc_debugTache
// ═══════════════════════════════════════════════════════════
// [_tache, _position] call hds_fnc_debugTache
//
//   _tache     <STRING> l'identifiant passé à BIS_fnc_taskCreate
//   _position  <ARRAY>  le repère à montrer quand le debug est allumé
//
// Retourne <BOOL>.
//
// À la place de :
//     if(hdssysteme)then{
//       [true,[_tache],...,(_m call BIS_fnc_randomPosTrigger),...] call BIS_fnc_taskCreate;
//     }else{
//       [true,[_tache],...,objnull,...] call BIS_fnc_taskCreate;
//     };
// on crée la tâche une seule fois, sans destination, puis :
//     [_tache, _m call BIS_fnc_randomPosTrigger] call hds_fnc_debugTache;
//
// BIS_fnc_setTask lit un tableau de deux éléments comme
// [objet, position exacte] : une position doit donc en avoir trois,
// sans quoi son x serait pris pour un objet. D'où le complément.
hds_fnc_debugTache = {
    params [["_tache", "", [""]], ["_position", [], [[]]]];

    if (_tache isEqualTo "") exitWith { false };
    if (count _position < 2) exitWith { false };

    private _pos = _position;
    if (count _pos isEqualTo 2) then { _pos = _pos + [0] };

    private _i = hds_debug_taches findIf { (_x select 0) isEqualTo _tache };
    if (_i < 0) then {
        hds_debug_taches pushBack [_tache, _pos];
    } else {
        hds_debug_taches set [_i, [_tache, _pos]];
    };

    [_tache, ([objNull, _pos] select (hdssysteme isEqualTo true))]
        call BIS_fnc_taskSetDestination;

    true
};

// ═══════════════════════════════════════════════════════════
// hds_fnc_debugAppliquer
// ═══════════════════════════════════════════════════════════
// Aucun paramètre. Rejoue l'état courant de hdssysteme sur tout le
// registre, et oublie au passage les marqueurs supprimés entre-temps
// (markerShape rend "" pour un marqueur qui n'existe plus).
//
// Retourne <BOOL> l'état appliqué.
hds_fnc_debugAppliquer = {
    private _actif = hdssysteme isEqualTo true;
    private _restants = [];

    {
        _x params ["_marqueur", "_alphaNormal"];

        if !((markerShape _marqueur) isEqualTo "") then {
            _marqueur setMarkerAlpha (
                [_alphaNormal, ([_alphaNormal] call hds_fnc_debugOpacite)] select _actif
            );
            _restants pushBack _x;
        };
    } forEach hds_debug_marqueurs;

    hds_debug_marqueurs = _restants;

    // ─── Les tâches ───
    // Une tâche supprimée sort du registre ; une tâche terminée y
    // reste, son repère ne doit pas trahir le debug non plus.
    private _taches = [];

    {
        _x params ["_tache", "_position"];

        if ([_tache] call BIS_fnc_taskExists) then {
            [_tache, ([objNull, _position] select _actif)]
                call BIS_fnc_taskSetDestination;
            _taches pushBack _x;
        };
    } forEach hds_debug_taches;

    hds_debug_taches = _taches;

    ["INFO", "DEBUG", format [
        "mode debug %1 - %2 marqueurs et %3 taches remis a jour",
        ["eteint", "allume"] select _actif,
        count _restants,
        count _taches
    ]] call hds_fnc_log;

    _actif
};
