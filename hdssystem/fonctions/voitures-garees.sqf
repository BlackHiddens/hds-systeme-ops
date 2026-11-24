/*
 * hds_fnc_voituresGarees
 * ─────────────────────────────────────────────────────────────
 * Pose des voitures civiles vides, garées le long des routes d'une
 * agglomération. Pas SUR la route : à côté, sur le bas-côté, alignées
 * avec la chaussée comme une voiture qu'on a garée.
 *
 *  0 : <ARRAY>  centre de l'agglomération
 *  1 : <NUMBER> rayon (m)
 *  2 : <NUMBER> nombre souhaité (facultatif : déduit du rayon)
 *
 * Retourne <NUMBER> : combien ont réellement trouvé leur place.
 *
 * ── Le problème à résoudre ──
 * createVehicle sur une position de route met la voiture au milieu de
 * la chaussée, et tout le monde la contourne. Pour la garer il faut
 * trois choses : la direction de la route, la largeur du bitume, et un
 * bas-côté libre et à peu près plat.
 *
 * ── La direction ──
 * roadsConnectedTo donne les tronçons voisins. Du centre de l'un vers
 * le centre de l'autre, on a l'axe de la route. La voiture s'aligne
 * dessus, dans un sens ou dans l'autre au hasard.
 *
 * ── La largeur ──
 * Pas besoin de la connaître : on s'écarte perpendiculairement par pas
 * de 50 cm, et on s'arrête au premier point qui n'est plus sur la
 * route. C'est vrai pour un chemin de terre comme pour une quatre
 * voies, sans rien coder en dur. On ajoute ensuite un mètre et demi
 * pour que la voiture entière soit dégagée, pas juste son centre.
 *
 * ── Le bas-côté ──
 * Un emplacement n'est retenu que s'il est hors de l'eau, sans
 * bâtiment ni véhicule à cinq mètres, sans arbre, rocher ni muret à
 * quatre mètres, et à peu près plat — une voiture penchée à trente
 * degrés dans un fossé, ça se voit tout de suite.
 *
 * setVectorDirAndUp plutôt que setDir puis setVectorUp : le second
 * écrase une partie du premier, et la voiture finit de travers.
 */

if (!isServer) exitWith { 0 };

params [
    ["_centre",  [0, 0, 0], [[]]],
    ["_rayon",   300, [0]],
    ["_nombre",  -1, [0]],
    ["_faction", civilian],
    ["_distanceMin", -1, [0]]
];

// ─── Ne pas se garer sous le nez du joueur ───
// Une voiture qui apparaît au bord du trottoir à trente mètres, ça se
// voit autant qu'un piéton. Même anneau que les habitants, même
// raison : c'est la logique d'Engima, dont la circulation ne pope pas
// parce qu'elle naît entre portée×0,6 et portée.
if (_distanceMin < 0) then {
    _distanceMin = missionNamespace getVariable ["hds_vie_distance_min", _rayon * 0.5];
};
if (_distanceMin > (_rayon * 0.85)) then { _distanceMin = _rayon * 0.85 };

private _joueurs = allPlayers select {
    alive _x && { !(_x isKindOf "HeadlessClient_F") }
};

// Aucun exitWith imbriqué : dans un then, il sort du test et non de la
// boucle.
private _fnVisible = {
    params ["_p"];
    private _vu = false;
    {
        if (!_vu) then {
            private _d = _x distance2D _p;
            if (_d < _distanceMin) then {
                _vu = true;
            } else {
                if (_d < (_rayon * 2)) then {
                    private _ecart = abs ((((_x getDir _p) - (getDir (vehicle _x))) + 540) % 360 - 180);
                    if (_ecart < 50) then { _vu = true };
                };
            };
        };
    } forEach _joueurs;
    _vu
};

if (count _centre < 2) exitWith { 0 };

// Déduit du rayon si on ne l'impose pas. Un hameau n'a pas besoin d'un
// parking : « pas besoin d'en faire trop pour les petites villes ».
if (_nombre < 0) then {
    _nombre = (round (_rayon / 60)) max 2 min 14;
};

// La même population que les voitures en circulation et que les
// habitants : une rue où les voitures garées ne sont pas du même peuple
// que celles qui roulent, ça se remarque.
private _classes = [_faction, "LEGER"] call hds_fnc_factionVehicules;

if (_classes isEqualTo []) exitWith {
    ["ALERTE", "CIVILS", "voitures garees : aucun vehicule civil dans le registre"]
        call hds_fnc_log;
    0
};

// ═══════════════════════════════════════════════════════════
// LES ROUTES QUI BORDENT DES HABITATIONS
// ═══════════════════════════════════════════════════════════
// On ne gare pas une voiture au milieu d'un champ : seulement là où
// quelqu'un pourrait habiter.
private _routes = (_centre nearRoads _rayon) select {
    (count (nearestObjects [getPos _x, ["House"], 60])) > 0
};

if (count _routes < 2) exitWith {
    ["INFO", "CIVILS", format [
        "voitures garees : pas de route habitee dans %1 m", _rayon
    ]] call hds_fnc_log;
    0
};

// ═══════════════════════════════════════════════════════════
// UN EMPLACEMENT SUR LE BAS-CÔTÉ
// ═══════════════════════════════════════════════════════════
private _fnPlat = {
    params ["_p"];
    private _h = [];
    {
        _h pushBack (getTerrainHeightASL [
            (_p select 0) + (_x select 0),
            (_p select 1) + (_x select 1)
        ]);
    } forEach [[2.5, 0], [-2.5, 0], [0, 2.5], [0, -2.5]];

    private _bas = _h select 0;
    private _haut = _h select 0;
    { if (_x < _bas) then { _bas = _x }; if (_x > _haut) then { _haut = _x } } forEach _h;

    (_haut - _bas) < 1.1
};

// Compteurs de refus : sans eux, « aucune voiture garée » ne dit pas
// pourquoi, et on règle les seuils à l'aveugle.
private _refusEau   = 0;
private _refusObjet = 0;
private _refusArbre = 0;
private _refusPente = 0;
private _refusVu    = 0;

private _fnLibre = {
    params ["_p"];

    if ([_p] call _fnVisible) exitWith { _refusVu = _refusVu + 1; false };

    if (surfaceIsWater _p) exitWith { _refusEau = _refusEau + 1; false };

    if !((nearestObjects [_p, ["AllVehicles", "Building", "Static"], 4]) isEqualTo []) exitWith {
        _refusObjet = _refusObjet + 1;
        false
    };

    private _obstacles = nearestTerrainObjects [
        _p, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "WALL", "FENCE",
             "HOUSE", "CHURCH", "FUELSTATION", "POWER LINES"], 3.5
    ];

    if !(_obstacles isEqualTo []) exitWith { _refusArbre = _refusArbre + 1; false };

    if !([_p] call _fnPlat) exitWith { _refusPente = _refusPente + 1; false };

    true
};

private _poses = 0;
private _essais = 0;
private _vues = [];

while { _poses < _nombre && { _essais < (_nombre * 25) } } do {

    _essais = _essais + 1;

    private _route = selectRandom _routes;
    private _a = getPos _route;

    // Deux voitures collées au même tronçon, ça ne ressemble à rien.
    private _dejaVu = false;
    { if ((_a distance2D _x) < 18) exitWith { _dejaVu = true } } forEach _vues;

    // Tronçon sous le nez d'un joueur : inutile de lui chercher un
    // bas-côté, il serait refusé au bout du compte. On s'épargne une
    // dizaine d'essais par voiture.
    if (!_dejaVu && { [_a] call _fnVisible }) then {
        _dejaVu = true;
        _refusVu = _refusVu + 1;
    };

    if (!_dejaVu) then {

        private _voisins = roadsConnectedTo _route;

        if !(_voisins isEqualTo []) then {

            private _b = getPos (selectRandom _voisins);
            private _dx = (_b select 0) - (_a select 0);
            private _dy = (_b select 1) - (_a select 1);

            if ((_dx * _dx + _dy * _dy) > 1) then {

                private _axe = ((_dx atan2 _dy) + 360) % 360;

                // Le côté décide du sens, et pas le hasard. Circulation
                // à droite : une voiture garée sur le bas-côté DROIT
                // regarde dans le sens de la marche ; sur le bas-côté
                // gauche, elle regarde à l'opposé. Un cap + 90°, c'est
                // la droite de l'axe.
                private _cote = selectRandom [90, -90];
                private _perp = _axe + _cote;
                private _sens = _axe + ([180, 0] select (_cote isEqualTo 90));

                // On s'écarte jusqu'à quitter le bitume, puis un mètre
                // et demi de plus pour dégager toute la carrosserie.
                private _place = [];
                private _d = 3;

                while { _d <= 12 && { _place isEqualTo [] } } do {
                    private _p = [
                        (_a select 0) + _d * sin _perp,
                        (_a select 1) + _d * cos _perp,
                        0
                    ];

                    if (!(isOnRoad _p)) then {
                        private _q = [
                            (_a select 0) + (_d + 1.5) * sin _perp,
                            (_a select 1) + (_d + 1.5) * cos _perp,
                            0
                        ];
                        if ([_q] call _fnLibre) then { _place = _q };
                        // Qu'elle convienne ou non, le bitume est
                        // passé : inutile de s'écarter davantage.
                        _d = 99;
                    };

                    _d = _d + 0.5;
                };

                if !(_place isEqualTo []) then {

                    private _veh = createVehicle [
                        selectRandom _classes, _place, [], 0, "CAN_COLLIDE"
                    ];

                    if (!isNull _veh) then {
                        _veh setPosATL _place;

                        // Alignée sur la route, dans le sens que son
                        // côté impose.
                        _veh setVectorDirAndUp [
                            [sin _sens, cos _sens, 0],
                            surfaceNormal (getPosATL _veh)
                        ];

                        // Une voiture garée depuis un moment : pas le
                        // plein, et pas sortie d'usine.
                        _veh setFuel (0.1 + random 0.8);
                        _veh setDamage (random 0.25);

                        _veh enableDynamicSimulation true;
                        _veh setVariable ["hds_civil_ambiance", true, true];

                        _vues pushBack _a;
                        _poses = _poses + 1;
                    };
                };
            };
        };
    };
};

if (_poses > 0 || { hdssysteme }) then {
    ["INFO", "CIVILS", format [
        "voitures garees : %1 sur %2 autour de [%3,%4] - %5 route(s) habitee(s), %6 essais, distance min %7 m - refus : vue %8, eau %9, objet %10, arbre %11, pente %12",
        _poses, _nombre,
        round (_centre select 0), round (_centre select 1),
        count _routes, _essais, round _distanceMin,
        _refusVu, _refusEau, _refusObjet, _refusArbre, _refusPente
    ]] call hds_fnc_log;
};

_poses
