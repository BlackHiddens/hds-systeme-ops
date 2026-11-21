/*
 * hds_fnc_miradors
 * ─────────────────────────────────────────────────────────────
 * Poste au moins un homme dans chaque tour de guet d'un secteur
 * d'occupation.
 *
 *  0 : <ARRAY>  centre du secteur
 *  1 : <NUMBER> rayon (m)
 *  2 : <SIDE>   camp
 *  3 : <ARRAY>  entrées CfgGroups du secteur, d'où sont tirées les
 *               classes d'hommes
 *
 * Retourne <NUMBER> : nombre de tours nouvellement occupées.
 *
 * ── Pourquoi à part de la garnison ──
 * hds_fnc_garnison répartit les hommes au ratio sur les places
 * disponibles. Un mirador n'a qu'une ou deux places sur plusieurs
 * centaines dans un village : au ratio, il reste vide neuf fois sur
 * dix. Or c'est précisément le poste qui compte — une tour vide, c'est
 * une tour qui ne sert à rien.
 *
 * Les bâtiments ordinaires ne changent pas : ils gardent le calcul au
 * ratio. Seules les tours deviennent obligatoires, et les hommes
 * postés ici s'ajoutent à la garnison au lieu de lui être pris.
 *
 * ── Comment une tour est reconnue ──
 * Deux voies, parce qu'une seule ne suffit pas :
 *
 *   1. une liste de classes (hds_miradors_classes, dans
 *      mes-parametres.sqf). Les classes vanilla ont été vérifiées
 *      dans les archives du jeu, pas citées de mémoire. Sûr, mais
 *      aveugle à ce qu'ajoutent les mods et les cartes tierces ;
 *   2. une mesure : un bâtiment haut, étroit, au moins aussi haut que
 *      large. Un immeuble d'habitation a lui aussi un étage, mais il
 *      est large — c'est ce qui les sépare.
 *
 * Dans les deux cas on exige au moins une place à 2,5 m du sol : une
 * « tour » où l'on ne peut poster personne n'en est pas une.
 *
 * ── Un seul homme à la fois ──
 * On ne fait pas naître une escouade par tour : les classes sont lues
 * directement dans les entrées CfgGroups (sous-classes Unit0, Unit1…),
 * et chaque sentinelle est créée à l'unité.
 */

params [
    ["_centre",        [0, 0, 0], [[]]],
    ["_rayon",         500, [0]],
    ["_camps",         east],
    ["_compositions",  [], [[], configNull]]
];

if (count _centre < 2) exitWith { 0 };

// ═══════════════════════════════════════════════════════════
// LES CLASSES D'HOMMES
// ═══════════════════════════════════════════════════════════
private _entrees = if (_compositions isEqualType []) then { _compositions } else { [_compositions] };
private _classes = [];

{
    private _cfg = _x;

    if (!isNull _cfg) then {
        {
            private _v = getText (_x >> "vehicle");
            if (_v != "" && { !(_v in _classes) }) then { _classes pushBack _v };
        } forEach (configProperties [_cfg, "isClass _x", true]);
    };
} forEach _entrees;

if (_classes isEqualTo []) exitWith {
    ["ALERTE", "OCCUPATIONS",
     "miradors : aucune classe d'homme dans les compositions du secteur"
    ] call hds_fnc_log;
    0
};

// ═══════════════════════════════════════════════════════════
// REPÉRER LES TOURS
// ═══════════════════════════════════════════════════════════
private _liste = missionNamespace getVariable ["hds_miradors_classes", []];
private _tours = [];

{
    private _b = _x;

    if (alive _b) then {

        private _retenu = (typeOf _b) in _liste;

        if (!_retenu) then {
            private _bb  = boundingBoxReal _b;
            private _min = _bb select 0;
            private _max = _bb select 1;

            private _larg = (_max select 0) - (_min select 0);
            private _prof = (_max select 1) - (_min select 1);
            private _haut = (_max select 2) - (_min select 2);
            private _emprise = _larg max _prof;

            // Haute, étroite, et au moins aussi haute que large
            _retenu = (_haut >= 4)
                && { _emprise <= 9 }
                && { _haut >= (_emprise * 0.9) };
        };

        if (_retenu) then {
            // Une place en hauteur, sinon ce n'est pas un poste
            private _hautes = ([_b, -1] call CBA_fnc_buildingPositions)
                select { (_x select 2) >= 2.5 };

            if !(_hautes isEqualTo []) then {
                _tours pushBack [_b, _hautes];
            };
        };
    };
} forEach (nearestObjects [_centre, ["Building"], _rayon]);

if (_tours isEqualTo []) exitWith {
    ["INFO", "OCCUPATIONS", format [
        "miradors : aucune tour dans %1 m", _rayon
    ]] call hds_fnc_log;
    0
};

// ═══════════════════════════════════════════════════════════
// POSTER
// ═══════════════════════════════════════════════════════════
// Un seul groupe pour toutes les sentinelles du secteur : autant de
// postes isolés, mais pas autant de groupes à simuler.
private _groupe = createGroup [_camps, true];
private _postes = 0;
private _deja   = 0;

{
    _x params ["_tour", "_hautes"];

    // Quelqu'un déjà en place ? On ne double pas le poste : la
    // garnison au ratio a pu y mettre un homme avant nous.
    private _occupe = false;

    {
        private _place = _x;
        if (({ alive _x } count (_place nearEntities ["Man", 3])) > 0) exitWith {
            _occupe = true;
        };
    } forEach _hautes;

    if (_occupe) then {
        _deja = _deja + 1;
    } else {

        private _place = selectRandom _hautes;

        // La forme tableau de createUnit ne rend pas l'unité de façon
        // fiable selon les versions : on la retrouve par différence
        // plutôt que de compter dessus.
        private _avant = units _groupe;
        _groupe createUnit [selectRandom _classes, _place, [], 0, "NONE"];

        private _nouveaux = (units _groupe) - _avant;
        private _homme = if (_nouveaux isEqualTo []) then { objNull } else { _nouveaux select 0 };

        if (isNull _homme) then {
            ["ALERTE", "OCCUPATIONS", format [
                "miradors : sentinelle non creee pour %1", typeOf _tour
            ]] call hds_fnc_log;
        } else {
            _homme setPosATL _place;

            // Il regarde vers l'extérieur du secteur : c'est de là que
            // ça vient, et c'est ce qu'on attend d'un guetteur.
            private _dx = (_place select 0) - (_centre select 0);
            private _dy = (_place select 1) - (_centre select 1);
            _homme setDir (((_dx atan2 _dy) + 360) % 360);

            // Il tient son poste. Sans PATH, il ne descend pas de sa
            // tour pour aller au contact — ce qui est tout l'intérêt
            // d'une tour.
            _homme disableAI "PATH";
            _homme setUnitPos "UP";

            _postes = _postes + 1;
        };
    };
} forEach _tours;

if (_postes > 0) then {
    _groupe enableDynamicSimulation true;
} else {
    // createGroup [side, true] se supprime tout seul une fois vide,
    // mais autant ne pas attendre.
    deleteGroup _groupe;
};

["INFO", "OCCUPATIONS", format [
    "miradors : %1 tour(s) dans %2 m - %3 occupee(s) a l'instant, %4 deja tenue(s)",
    count _tours, _rayon, _postes, _deja
]] call hds_fnc_log;

_postes
