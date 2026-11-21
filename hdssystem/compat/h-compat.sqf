/*
 * hdssystem\compat\h-compat.sqf
 * ─────────────────────────────────────────────────────────────
 * Couche de compatibilité HDS.
 *
 * PRÉREQUIS MOD : CBA_A3 uniquement.
 *
 * Plus aucune branche ACE. Les wrappers testaient « si ACE est là,
 * faire autrement », ce qui ne créait pas de dépendance mais faisait
 * diverger le comportement d'une machine à l'autre — et c'est
 * exactement ce qui a produit le bug de garnison décrit plus bas.
 * Une seule implémentation, la même partout.
 */

// ═══════════════════════════════════════════════════════════
// GARNISON
//
// Signature conservée à l'identique des anciens appels :
//   [_position, _direction, _unites, _rayon, _type, _surToit, _teleport]
//
// Retourne : <NUMBER> nombre d'hommes réellement postés
//
// ── Le bug que ceci corrige ──
// La version précédente déléguait à CBA_fnc_taskDefend, qui donne des
// WAYPOINTS : les hommes marchent vers les bâtiments. Or l'appelant
// enchaînait aussitôt avec BIS_fnc_ambientAnimCombat, qui fige chaque
// homme LÀ OÙ IL EST. Ils se figeaient donc dehors, au point
// d'apparition, et n'entraient jamais. Avec l'ancienne garnison ACE,
// qui téléporte, animer juste après fonctionnait.
//
// On place donc nous-mêmes, puis on anime. L'ordre est le sujet.
//
// ── Ce qu'on vise ──
// Une zone bâtie doit avoir l'air habitée : des hommes aux fenêtres et
// aux étages, orientés au hasard, certains en animation d'ambiance,
// d'autres simplement postés. Les animés sortent d'eux-mêmes de leur
// animation au contact ; les postés tiennent leur fenêtre.
//
// ── Limite assumée ──
// _surToit n'est pas honoré : CBA_fnc_buildingPositions rend les
// positions de toit mélangées aux autres, sans moyen fiable de les
// distinguer. On les garde toutes.
// ═══════════════════════════════════════════════════════════
hds_fnc_garnison = {
    params [
        "_position",
        ["_direction", 0],
        ["_unites", []],
        ["_rayon", 50],
        ["_type", 1],
        ["_surToit", false],
        ["_teleport", true]
    ];

    // CBA_fnc_taskDefend exige trois composantes quand on lui passe un
    // tableau : un [x, y] seul lui fait signaler une erreur de type et
    // perdre la position. On complete avant de l'appeler.
    if (_position isEqualType [] && { count _position == 2 }) then {
        _position = _position + [0];
    };

    _unites = _unites select { !isNull _x && { alive _x } };
    if (_unites isEqualTo []) exitWith { 0 };

    private _groupe = group (_unites select 0);
    if (isNull _groupe) exitWith { 0 };

    // ─── Places disponibles dans le rayon ───
    private _places = [];
    {
        _places append ([_x, -1] call CBA_fnc_buildingPositions);
    } forEach ((nearestObjects [_position, ["Building"], _rayon]) select { alive _x });

    // ─── Aucun bâtiment : défense de zone, CBA s'en charge ───
    if (_places isEqualTo []) exitWith {
        [_groupe, _position, _rayon, 3, 0, 1] call CBA_fnc_taskDefend;
        _groupe setVariable ["hds_garrison", true, true];
        if (hdssysteme) then {
            diag_log format ["[HDS][GARNISON] %1 : aucun batiment dans %2 m, defense de zone",
                groupId _groupe, _rayon];
        };
        0
    };

    _places = _places call BIS_fnc_arrayShuffle;

    // ─── Mise en place, puis animation ───
    private _n = 0;
    {
        if (count _places == 0) exitWith {};
        private _place = _places deleteAt 0;
        private _u = _x;

        _u setPosATL _place;
        _u setDir (random 360);
        doStop _u;

        if (random 1 < 0.6) then {
            // Animation d'ambiance : il a l'air occupé, et il en sort
            // tout seul dès qu'il repère quelqu'un.
            [_u, "STAND", "FULL"] call BIS_fnc_ambientAnimCombat;
        } else {
            // Posté à sa fenêtre : il tient, il ne déambule pas.
            _u setUnitPos (selectRandom ["MIDDLE", "UP"]);
            _u disableAI "PATH";
        };

        _n = _n + 1;
    } forEach _unites;

    _groupe setVariable ["hds_garrison", true, true];

    if (hdssysteme) then {
        diag_log format ["[HDS][GARNISON] %1 : %2 hommes postes sur %3 places, rayon %4 m",
            groupId _groupe, _n, _n + count _places, _rayon];
    };

    _n
};

// ═══════════════════════════════════════════════════════════
// ARSENAL
//
// Signature : [_caisse, _contenu]
//   _contenu = true           → arsenal complet
//   _contenu = [classnames]   → arsenal restreint à cette liste
// ═══════════════════════════════════════════════════════════
hds_fnc_arsenal = {
    params ["_caisse", ["_contenu", true]];

    if (isNull _caisse) exitWith { false };

    if (_contenu isEqualType []) then {
        // Arsenal restreint : on alimente le cargo virtuel de la caisse,
        // puis on ouvre l'arsenal limité à ce cargo.
        // NOTE : à valider en jeu — chaque BIS_fnc_addVirtual*Cargo ne
        // retient que les classes de son propre type.
        [_caisse, _contenu] call BIS_fnc_addVirtualWeaponCargo;
        [_caisse, _contenu] call BIS_fnc_addVirtualMagazineCargo;
        [_caisse, _contenu] call BIS_fnc_addVirtualItemCargo;
        [_caisse, _contenu] call BIS_fnc_addVirtualBackpackCargo;
        ["AmmoboxInit", [_caisse, false]] call BIS_fnc_arsenal;
    } else {
        ["AmmoboxInit", [_caisse, true]] call BIS_fnc_arsenal;
    };

    if (hdssysteme) then {
        diag_log format ["[HDS][COMPAT] Arsenal vanilla sur %1", typeOf _caisse];
    };
    true
};

// ═══════════════════════════════════════════════════════════
// CONTRÔLE DU PRÉREQUIS
// ═══════════════════════════════════════════════════════════
if (!cbaestactive) then {
    diag_log "[HDS][COMPAT] /!\ CBA_A3 ABSENT - le systeme ne peut pas fonctionner.";
    ["<t color='#ff4444' size='1.3'>HDS : CBA_A3 est requis</t>"] remoteExecCall ["parseText", 0];
};

diag_log format ["[HDS][COMPAT] Charge - CBA:%1", cbaestactive];
