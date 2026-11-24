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
 * 5 : <NUMBER> distance minimale d'apparition (m). -1 : celle posée par
 *              fnc_hds_vie_civile, sinon la moitié du rayon.
 * 6 : <BOOL>   population permanente : elle n'est pas balayée quand
 *              les joueurs s'éloignent. À réserver au scénario, qui
 *              sait ce qu'il demande.
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
    ["_marqueurvisible", false],
    ["_distanceMin",     -1],
    ["_permanent",       false]
];

// ─── Balayé ou pas ───
// fnc_hds_vie_civile supprime tout ce qui porte « hds_civil_ambiance »
// dès que le joueur le plus proche dépasse la distance d'oubli. C'est
// ce qui économise le serveur quand la population suit les joueurs.
//
// Une population posée exprès par le scénario, elle, doit tenir : sans
// ça, peupler un village à trois kilomètres des joueurs ne sert à rien,
// il serait vidé huit secondes plus tard. _permanent à true retire la
// marque — et donc aussi le ménage automatique : c'est au scénario de
// savoir ce qu'il demande.

// ─── À quelle distance d'un joueur on a le droit d'apparaître ───
// -1 : la valeur posée par fnc_hds_vie_civile, sinon la moitié du
// rayon. C'est la même idée que l'anneau d'Engima, qui ne fait naître
// ses voitures qu'entre portée×0,6 et portée : on ne voit jamais rien
// apparaître, et c'est pour ça que la circulation, elle, ne pope pas.
if (_distanceMin < 0) then {
    _distanceMin = missionNamespace getVariable ["hds_vie_distance_min", _taille * 0.5];
};
if (_distanceMin > (_taille * 0.85)) then { _distanceMin = _taille * 0.85 };

// ─── Pourquoi -1 et plus 0 ───
// 0 voulait dire « n'ajoute rien au nombre déduit des maisons ». Pour
// un paramètre de densité, c'est le plus mauvais défaut possible :
// appelée sans argument, la fonction donnait sa population la plus
// maigre — et dans un lieu sans maison, exactement un habitant.
//
// -1 veut maintenant dire « sers-toi de la densité en vigueur ».
// Celle-ci vient d'abord du scénario — hds_vie_habitants, posée par
// fnc_hds_vie_civile depuis init-scenario.sqf — et seulement à défaut
// du curseur du menu CBA, pour une mission qui n'utilise pas la vie
// civile mais appelle quand même cette fonction.
//
// Un 0 explicite reste un 0 : quand fnc_hds_vie_civile calcule un
// supplément nul pour la rase campagne, c'est bien ce qu'il veut.
if (_ratio < 0) then {
    _ratio = round (missionNamespace getVariable [
        "hds_vie_habitants",
        (missionNamespace getVariable ["hds_civils_densite", 8]) / 2
    ]);
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
// Le nombre déduit des maisons est plafonné : sur un rayon large et
// en pleine ville, « une maison sur trois » donnait trente habitants,
// soit soixante unités avec les piétons. La densité voulue par le
// scénario doit rester le terme qui décide.
private _nb = round (((_nbMaisons / 3) min 10) + _ratio);
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

// ═════════════════════════════════════════════════════════
// NE PAS APPARAÎTRE SOUS LE NEZ DU JOUEUR
// ════════════════════════════════════════════════════════
// Deux règles, parce que la distance seule ne suffit pas : un homme
// qui se matérialise droit devant se remarque même à 300 m, alors
// qu'à 150 m dans le dos personne ne le voit jamais arriver.
private _joueurs = allPlayers select {
    alive _x && { !(_x isKindOf "HeadlessClient_F") }
};

// ════════════════════════════════════════════════════════
// LES MILITAIRES, ET CE QU'ILS TIENNENT
// ════════════════════════════════════════════════════════
// Un civil peut passer PRÈS d'une position tenue, jamais dedans. On
// ne cherche pas la zone déclarée par le scénario — un ennemi posé à
// la main dans l'éditeur n'en fait partie d'aucune — mais les soldats
// eux-mêmes : ça couvre tout, quelle qu'en soit l'origine.
//
// Les joueurs et leurs équipiers ne comptent pas : on veut des civils
// AUTOUR des joueurs, c'est tout le propos.
private _grpJoueurs = allPlayers apply { group _x };
private _soldats = allUnits select {
    alive _x
    && { (side _x) != civilian }
    && { !((group _x) in _grpJoueurs) }
};

// Les zones d'occupation posées par le scénario. Une zone existe dès
// que fnc_hds_occupations l'a marquée, parfois avant que ses hommes
// soient en place : sans ça, des civils s'y installaient dans
// l'intervalle. On écarte « hds_occups_civil_ », qui est le nôtre.
private _zonesOccupees = [];
{
    if (((_x find "hds_occups_") == 0) && { (_x find "hds_occups_civil_") != 0 }) then {
        _zonesOccupees pushBack [getMarkerPos _x, (markerSize _x) select 0];
    };
} forEach allMapMarkers;

private _fnSoldatProche = {
    params ["_pos", "_d"];
    private _proche = false;
    {
        if (!_proche && { (_x distance2D _pos) < _d }) then { _proche = true };
    } forEach _soldats;

    {
        if (!_proche && { (_pos distance2D (_x select 0)) < ((_x select 1) + 40) }) then {
            _proche = true;
        };
    } forEach _zonesOccupees;

    _proche
};

// Un bâtiment militaire n'accueille pas de civil assis chez lui. Deux
// signaux, parce qu'aucun des deux ne suffit seul :
//
//   — le nom de classe. Il n'existe pas de drapeau « militaire » dans
//     la config ; on reconnaît donc des morceaux de nom. La liste est
//     volontairement courte et sans ambiguïté : « cargo_house » par
//     exemple n'y est PAS, c'est de l'habitat sur Altis et Stratis.
//   — la présence de soldats. C'est le cas que tu décris : des
//     hommes qui tiennent un bâtiment ordinaire, en pleine ville.
private _motsMilitaires = [
    "bunker", "hbarrier", "barrack", "hangar", "airport", "mil_",
    "military", "radar", "watchtower", "guardhouse", "fort_", "camonet",
    "sandbag", "pillbox", "cargo_patrol", "cargo_hq", "cargo_tower",
    "checkpoint", "ammo", "command"
];

private _fnBatimentInterdit = {
    params ["_b"];
    private _nom = toLower (typeOf _b);
    private _interdit = false;
    {
        if (!_interdit && { (_nom find _x) >= 0 }) then { _interdit = true };
    } forEach _motsMilitaires;

    if (!_interdit) then {
        // Tenu par des hommes en armes : un civil n'y entre pas.
        if ([getPosATL _b, 30] call _fnSoldatProche) then { _interdit = true };
    };

    _interdit
};

// Le cône de vision se mesure sur la direction du CORPS, pas du
// regard : eyeDirection vaut ce que vaut sa synchronisation vers le
// serveur, alors que getDir est fiable partout. On ne vise pas la
// précision, juste « pas droit devant ».
//
// Deux précautions d'écriture :
//   — le cône ne vaut que pour un joueur ASSEZ PROCHE. Celui de
//     quelqu'un à deux kilomètres balaierait un tiers de la carte, et
//     plus aucune position ne passerait.
//   — aucun exitWith ici. Dans un then imbriqué, il sort du TEST et
//     non de la boucle : c'est exactement le bug qui, dans ce même
//     fichier, ne laissait jamais apparaître qu'un seul habitant.
private _fnVisible = {
    params ["_pos"];
    private _vu = false;
    {
        if (!_vu) then {
            private _d = _x distance2D _pos;
            if (_d < _distanceMin) then {
                _vu = true;
            } else {
                if (_d < (_taille * 2)) then {
                    private _ecart = abs ((((_x getDir _pos) - (getDir (vehicle _x))) + 540) % 360 - 180);
                    if (_ecart < 50) then { _vu = true };
                };
            };
        };
    } forEach _joueurs;
    _vu
};

// Une position dans l'ANNEAU, pas dans le disque : entre la distance
// minimale et le bord de la zone. Si rien ne convient après vingt
// tirages — un joueur au milieu d'un village regarde forcément
// quelque part — on rend [] et on ne place rien. Le cycle suivant
// retentera, huit secondes plus tard, depuis un autre endroit.
private _fnQuelquePart = {
    params ["_rayon"];
    private _min = _distanceMin min (_rayon * 0.85);
    private _trouve = [];
    for "_essai" from 1 to 20 do {
        if (_trouve isEqualTo []) then {
            private _a = random 360;
            // Tirage uniforme en SURFACE sur l'anneau, sinon tout se
            // tasse contre le bord intérieur.
            private _d = sqrt (_min * _min + random ((_rayon * _rayon) - (_min * _min)));
            private _p = [
                (_centre select 0) + _d * sin _a,
                (_centre select 1) + _d * cos _a,
                0
            ];
            // 200 m des soldats : la ronde fait 120 m de rayon, donc
            // un civil peut s'approcher à 80 m d'une position tenue
            // sans jamais la traverser.
            if (!([_p] call _fnVisible) && { !([_p, 200] call _fnSoldatProche) }) then {
                _trouve = _p;
            };
        };
    };
    _trouve
};

// Les routes de l'agglomération. Un piéton marche le long d'une rue,
// mais JAMAIS dessus : il naissait à getPos d'un tronçon, c'est-à-dire
// au milieu du bitume, là où le trafic d'Engima lui passe dessus.
private _routes = _centre nearRoads _taille;

// À côté de la route, pas dessus : on s'éloigne dans une direction au
// hasard jusqu'à quitter le bitume. Les voitures garées, elles, ont
// besoin de l'axe exact de la rue pour s'aligner dessus ; un piéton
// n'a besoin que de ne pas être sur la chaussée.
private _fnBordDeRoute = {
    private _p = [];
    for "_essai" from 1 to 12 do {
        if (_p isEqualTo []) then {
            private _r = selectRandom _routes;
            private _a = getPos _r;
            if (((_a distance2D _centre) <= _taille) && { !([_a] call _fnVisible) }) then {
                private _cap = random 360;
                private _d = 5;
                while { _d <= 16 && { _p isEqualTo [] } } do {
                    private _bord = [
                        (_a select 0) + _d * sin _cap,
                        (_a select 1) + _d * cos _cap,
                        0
                    ];
                    if (!(isOnRoad _bord)) then {
                        // Deux mètres de plus : le premier point hors
                        // chaussée est le bord exact du bitume, et le
                        // trafic d'Engima y passe.
                        private _q = [
                            (_a select 0) + (_d + 2) * sin _cap,
                            (_a select 1) + (_d + 2) * cos _cap,
                            0
                        ];
                        if (!(surfaceIsWater _q)
                            && { !([_q] call _fnVisible) }
                            && { !([_q, 200] call _fnSoldatProche) }) then {
                            _p = _q;
                        };
                        // Le bitume est passé : inutile de s'écarter plus.
                        _d = 99;
                    };
                    _d = _d + 1.5;
                };
            };
        };
    };
    _p
};

// ─── Le repli : autour de chez soi ───
// Un piéton marche aux abords d'une rue. Quand il n'y en a aucune
// d'exploitable, la seule raison acceptable d'en poser un en pleine
// campagne est la maison isolée : on simule son propriétaire, qui
// traîne autour de chez lui. Sans maison non plus, on ne pose rien.
private _fnAutourDUneMaison = {
    private _maisons = (nearestObjects [_centre, ["House"], _taille]) select {
        !([_x] call _fnBatimentInterdit)
    };
    private _p = [];
    if !(_maisons isEqualTo []) then {
        for "_essai" from 1 to 10 do {
            if (_p isEqualTo []) then {
                private _m = getPosATL (selectRandom _maisons);
                private _cap = random 360;
                private _d = 8 + random 14;
                private _c = [
                    (_m select 0) + _d * sin _cap,
                    (_m select 1) + _d * cos _cap,
                    0
                ];
                if (((_c distance2D _centre) <= _taille)
                    && { !(isOnRoad _c) }
                    && { !(surfaceIsWater _c) }
                    && { !([_c] call _fnVisible) }
                    && { !([_c, 200] call _fnSoldatProche) }) then {
                    _p = _c;
                };
            };
        };
    };
    _p
};

private _poses = 0;

for "_i" from 1 to _nb do {

    // ─── Casanier : assis chez lui ───
    private _posC = [_taille] call _fnQuelquePart;

    // La maison d'abord, l'homme ensuite. Un casanier sans chez-lui
    // restait dans le groupe commun et aurait suivi son chef à travers
    // le village — soit exactement le comportement militaire qu'on
    // cherche à supprimer. Pas de maison, pas de casanier : le
    // peuplement se fera ailleurs au cycle suivant.
    private _chezLui = [];
    if !(_posC isEqualTo []) then {
        private _maisons = (nearestObjects [_posC, ["House"], 80]) select {
            !([_x] call _fnBatimentInterdit)
            && { !(([_x] call BIS_fnc_buildingPositions) isEqualTo []) }
        };
        if !(_maisons isEqualTo []) then {
            private _places = [selectRandom _maisons] call BIS_fnc_buildingPositions;
            if !(_places isEqualTo []) then { _chezLui = selectRandom _places };
        };
    };

    private _hommeC = if (_chezLui isEqualTo []) then { objNull } else {
        [_grpMaison, selectRandom _classes, _chezLui] call _fnCreer
    };

    if (!isNull _hommeC) then {
        // ─── Plus de hds_fnc_garnison ───
        // C'est la fonction de garnison MILITAIRE : elle pose
        // BIS_fnc_ambientAnimCombat, setUnitPos "UP" et disableAI
        // "PATH" — un homme en poste à sa fenêtre. Sur un civil, ça
        // donnait exactement ce qu'on reprochait au système : des
        // habitants qui se comportent comme des soldats. Et elle
        // cherchait ses places dans "Building", bunkers et hangars
        // compris.
        _hommeC setPosATL _chezLui;
        _hommeC setDir (random 360);
        [_hommeC, "SIT_LOW_U", "NONE"] call BIS_fnc_ambientAnim;

        // Un civil ne tient pas une position : ni posture de combat,
        // ni IA de déplacement coupée.
        (group _hommeC) setBehaviour "CARELESS";
        (group _hommeC) setCombatMode "BLUE";
        _hommeC setUnitPos "AUTO";

        _hommeC enableDynamicSimulation true;

        // Civil d'ambiance : fnc_hds_vie_civile le retirera quand plus
        // aucun joueur ne sera assez près pour le voir. La marque est
        // ce qui le distingue d'un otage ou d'un VIP posé par une
        // mission, qui ne doit jamais être balayé.
        if (!_permanent) then {
            _hommeC setVariable ["hds_civil_ambiance", true, true];
        };
        _poses = _poses + 1;
    };

    // ─── Piéton : il déambule, et on le voit ───
    // Le bord d'une route d'abord, pour qu'il ait l'air d'aller
    // quelque part ; n'importe où dans l'anneau si aucune rue ne
    // convient. Jamais sur la chaussée.
    private _depart = if (_routes isEqualTo []) then { [] } else { call _fnBordDeRoute };

    // Pas de rue : chez lui, ou nulle part. L'ancien repli le posait
    // n'importe où dans l'anneau, et c'est ainsi qu'on se retrouvait
    // avec un promeneur au milieu d'un champ.
    if (_depart isEqualTo []) then { _depart = call _fnAutourDUneMaison };

    private _grpP = if (_depart isEqualTo []) then { grpNull } else { createGroup [civilian, true] };
    private _hommeP = if (isNull _grpP) then { objNull } else {
        [_grpP, selectRandom _classes, _depart] call _fnCreer
    };

    if (isNull _hommeP) then {
        if (!isNull _grpP) then { deleteGroup _grpP };
    } else {
        _hommeP setPosATL _depart;

        // ── Les deux taskPatrol ne prennent pas la même chose en
        //    quatrième position ──
        //   BIS_fnc_taskPatrol : [groupe, position, distance
        //       maximale entre deux étapes, LISTE NOIRE DE ZONES]
        //   CBA_fnc_taskPatrol : [groupe, position, rayon,
        //       NOMBRE D'ÉTAPES]
        //
        // Le 4 passé à la version BIS était lu comme une liste
        // noire. Elle vérifie son type, n'y trouve pas un tableau,
        // et sort sans créer un seul waypoint :
        //
        //   if ((typeName _blacklist) != (typeName [])) exitWith {};
        //
        // D'où des piétons parfaitement vivants et parfaitement
        // immobiles, avec le seul waypoint que tout groupe
        // possède d'office. C'est la version CBA qu'il fallait.
        // ─── Une ronde LE LONG DES RUES ───
        // taskPatrol tire ses étapes au hasard dans un cercle : le
        // piéton finissait au milieu d'un champ ou dans un bois, ce qui
        // n'a aucun sens pour quelqu'un qui habite là. On construit
        // donc les étapes nous-mêmes, chacune au bord d'une rue, et
        // aucune à moins de 60 m d'un soldat : il passe près d'une
        // position tenue, il ne la traverse jamais.
        private _etapes = [];
        private _ruesProches = _depart nearRoads 220;

        {
            if (count _etapes < 5) then {
                private _a = getPos _x;
                private _assezLoin = true;
                { if ((_a distance2D _x) < 70) then { _assezLoin = false } } forEach _etapes;

                if (_assezLoin) then {
                    private _cap = random 360;
                    private _d = 5;
                    private _q = [];
                    while { _d <= 16 && { _q isEqualTo [] } } do {
                        private _bord = [
                            (_a select 0) + _d * sin _cap,
                            (_a select 1) + _d * cos _cap,
                            0
                        ];
                        if (!(isOnRoad _bord)) then {
                            private _c = [
                                (_a select 0) + (_d + 2) * sin _cap,
                                (_a select 1) + (_d + 2) * cos _cap,
                                0
                            ];
                            if (!(surfaceIsWater _c)
                                && { !([_c, 60] call _fnSoldatProche) }) then {
                                _q = _c;
                            };
                            _d = 99;
                        };
                        _d = _d + 2;
                    };
                    if !(_q isEqualTo []) then { _etapes pushBack _q };
                };
            };
            // Quarante candidats mélangés, pas trois cents : en ville
            // nearRoads en rend beaucoup, et chacun se paie en tests
            // contre tous les soldats, pour chaque piéton.
        } forEach ((_ruesProches call BIS_fnc_arrayShuffle) select [0, 40]);

        if (count _etapes >= 2) then {
            {
                private _wp = _grpP addWaypoint [_x, 0];
                _wp setWaypointType "MOVE";
                _wp setWaypointSpeed "LIMITED";
                _wp setWaypointBehaviour "CARELESS";
                _wp setWaypointCompletionRadius 8;
            } forEach _etapes;

            private _boucle = _grpP addWaypoint [_depart, 0];
            _boucle setWaypointType "CYCLE";
        } else {
            // Aucune rue exploitable autour de lui : il tourne autour
            // de chez lui, sur quarante mètres. S'il n'avait pas de
            // maison, il n'aurait pas été créé.
            [_grpP, _depart, 40, 3] call CBA_fnc_taskPatrol;
        };
        _grpP setBehaviour "CARELESS";
        _grpP setSpeedMode "LIMITED";

        // Pas de simulation dynamique sur un pieton d'ambiance : il
        // est deja supprime des qu'il s'eloigne, le geler en plus ne
        // fait qu'ajouter une facon de le voir immobile.
        if (!_permanent) then {
            _hommeP setVariable ["hds_civil_ambiance", true, true];
        };
        _poses = _poses + 1;
    };
};

["INFO", "CIVILS", format [
    "%1 civil(s) places sur %2 voulus autour de [%3,%4] - %5 route(s) dans la zone",
    _poses, _nb * 2,
    round (_centre select 0), round (_centre select 1),
    count _routes
]] call hds_fnc_log;

true
