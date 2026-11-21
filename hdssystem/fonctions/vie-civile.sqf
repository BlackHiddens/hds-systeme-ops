/*
 * fnc_hds_vie_civile
 * ─────────────────────────────────────────────────────────────
 * Vie civile entretenue AUTOUR DES JOUEURS : du trafic sur les routes
 * et de la population dans les agglomérations proches, rien ailleurs.
 *
 * 0 : <NUMBER> densité : véhicules en circulation autour des joueurs
 * 1 : <BOOL>   peupler aussi les agglomérations proches
 * 2 : <ARRAY>  types de localisation à peupler
 * 3 : <NUMBER> distance d'apparition minimale (m)
 * 4 : <NUMBER> distance d'apparition maximale (m)
 * 5 : <NUMBER> distance d'oubli : au-delà, on supprime (m)
 *
 * À lancer avec spawn :
 *   [] spawn fnc_hds_vie_civile;
 *   [15, true, ["NameCity"]] spawn fnc_hds_vie_civile;
 *
 * ─────────────────────────────────────────────────────────────
 * ── Ce que la version précédente faisait de travers ──
 * Elle posait douze véhicules sur des routes tirées au hasard SUR
 * TOUTE LA CARTE, une fois pour toutes, sans jamais rien supprimer.
 * Conséquence : les routes étaient vides là où les joueurs se
 * trouvaient, et douze véhicules tournaient dans le vide ailleurs.
 *
 * C'est une régression de ma part. En remplaçant le script d'Engima
 * par du code maison, j'ai repris ce qu'il produisait — des voitures
 * qui roulent — sans reprendre ce qui comptait vraiment : il les
 * entretenait dans un anneau autour des joueurs et supprimait celles
 * qui s'éloignaient. Les réglages d'origine, retrouvés dans
 * l'historique du dépôt, étaient MIN_SPAWN_DISTANCE 300,
 * MAX_SPAWN_DISTANCE 500, VEHICLES_COUNT 5.
 *
 * ── Le principe, donc ──
 * Un seul cycle, toutes les huit secondes :
 *
 *   1. OUBLI    tout civil d'ambiance dont le joueur le plus proche
 *               est au-delà de la distance d'oubli est supprimé, lui
 *               et son véhicule. Plus personne connecté : on vide.
 *   2. PEUPLER  une agglomération dont un joueur s'approche reçoit sa
 *               population ; désertée, elle est oubliée par l'étape 1
 *               et se repeuplera à la prochaine visite.
 *   3. TRAFIC   on complète jusqu'à la densité voulue, en faisant
 *               apparaître sur une route de l'anneau [min, max] autour
 *               d'un joueur tiré au sort. Assez loin pour qu'on ne
 *               voie rien apparaître, assez près pour que la route
 *               soit vivante là où on roule.
 *
 * Seuls les civils marqués « hds_civil_ambiance » sont concernés. Un
 * otage, un VIP ou un civil posé par une mission ne porte pas cette
 * marque et ne sera jamais supprimé par ce balayage.
 *
 * ── Les réglages ──
 * La densité se règle en jeu : Échap → Options → Options des addons →
 * HDS → « Densité du trafic civil ». Elle est relue à chaque cycle,
 * donc elle s'applique tout de suite. Le paramètre 0 de cette fonction
 * ne sert plus que de valeur de départ.
 *
 * Et « Population civile » décoché arrête tout, y compris le trafic.
 */

if (!isServer) exitWith {};

params [
    ["_densite",          8],
    ["_peupler",          true],
    ["_typeLocalisation", ["NameCity", "NameVillage"]],
    ["_distanceMin",      300],
    ["_distanceMax",      500],
    ["_distanceOubli",    900]
];

if (!canSuspend) exitWith {
    ["ERREUR", "CIVILS", "fnc_hds_vie_civile doit etre lancee avec spawn, pas call"]
        call hds_fnc_log;
};

// Le registre est rempli de façon asynchrone au démarrage.
if (!hds_factions_pret) then { waitUntil { hds_factions_pret } };

// ─── Une seule faction civile, pour tout ───
// Les véhicules et les hommes étaient demandés séparément, et les deux
// fonctions ne résolvent pas la faction de la même façon :
// hds_fnc_factionVehicules passe par hds_fnc_factionResoudre, pendant
// que hds_fnc_factionHommes se contente du camp et prend la première
// faction civile venue. Résultat, le chauffeur et sa voiture pouvaient
// sortir de deux populations différentes.
//
// On résout donc UNE fois, et on sert tout le monde avec le même id :
// les voitures, les chauffeurs, et les habitants des agglomérations.
([civilian] call hds_fnc_factionResoudre) params ["_idCiv", "_sideCiv"];

private _classesVeh = [_idCiv, "LEGER"] call hds_fnc_factionVehicules;
private _classesHom = [_idCiv] call hds_fnc_factionHommes;

["INFO", "CIVILS", format [
    "population civile retenue : %1 - %2 vehicule(s), %3 homme(s)",
    (["aucune", _idCiv] select (_idCiv != "")),
    count _classesVeh, count _classesHom
]] call hds_fnc_log;

if (_classesVeh isEqualTo [] || { _classesHom isEqualTo [] }) exitWith {
    ["ALERTE", "CIVILS", format [
        "pas de vie civile : %1 vehicule(s) et %2 homme(s) civils dans le registre",
        count _classesVeh, count _classesHom
    ]] call hds_fnc_log;
};

// Valeur de départ du réglage en jeu, si le menu CBA ne l'a pas encore
// posée (API changée, réglage pas encore reçu du serveur).
if (isNil "hds_civils_densite") then { hds_civils_densite = _densite };

// ═══════════════════════════════════════════════════════════
// LES AGGLOMÉRATIONS, RELEVÉES UNE SEULE FOIS
// ═══════════════════════════════════════════════════════════
// [centre, rayon, peuplée ?]
private _lieux = [];

if (_peupler) then {
    {
        // « size » sur une Location rend un TABLEAU [x, y], pas un
        // nombre : on prend le plus grand des deux côtés, borné.
        private _dim = size _x;
        private _taille = 300;
        if (_dim isEqualType [] && { count _dim >= 2 }) then {
            _taille = ((((_dim select 0) max (_dim select 1)) * 2) max 150) min 600;
        };

        _lieux pushBack [locationPosition _x, _taille, false];
    } forEach (nearestLocations [
        [worldSize / 2, worldSize / 2, 0], _typeLocalisation, worldSize
    ]);

    ["INFO", "CIVILS", format [
        "%1 agglomeration(s) reperee(s) - peuplees a l'approche des joueurs",
        count _lieux
    ]] call hds_fnc_log;
};

// ═══════════════════════════════════════════════════════════
// OUTILS
// ═══════════════════════════════════════════════════════════

// Tout ce que cette fonction a fait naître, et rien d'autre.
private _fnAmbiance = {
    (allUnits + vehicles) select { _x getVariable ["hds_civil_ambiance", false] }
};

// Vrai si aucun joueur n'est à moins de _d mètres.
private _fnLoin = {
    params ["_objet", "_joueurs", "_d"];
    private _proche = false;
    { if ((_objet distance2D _x) < _d) exitWith { _proche = true } } forEach _joueurs;
    !_proche
};

// Supprime un civil et, s'il conduit, son véhicule avec l'équipage.
private _fnSupprimer = {
    params ["_objet"];
    private _v = if (_objet isKindOf "Man") then { vehicle _objet } else { _objet };

    if (!(_v isEqualTo _objet) || { !(_v isKindOf "Man") }) then {
        { deleteVehicle _x } forEach (crew _v);
        deleteVehicle _v;
    } else {
        deleteVehicle _objet;
    };
};

// Des joueurs éloignés les uns des autres jouent chacun de leur côté :
// chacun doit avoir son ambiance, pas se partager un quota commun.
// Une passe simple suffit — on n'a pas besoin d'un vrai partitionnement,
// seulement de savoir qui est avec qui.
private _fnGrappes = {
    params ["_joueurs", "_rayon"];

    private _grappes = [];

    {
        private _j = _x;
        private _place = false;

        {
            if (!_place && { (_j distance2D (_x select 0)) < _rayon }) then {
                (_x select 1) pushBack _j;
                _place = true;
            };
        } forEach _grappes;

        if (!_place) then { _grappes pushBack [getPosATL _j, [_j]] };
    } forEach _joueurs;

    _grappes
};

// Plus dense en ville qu'à la campagne. « Un trafic correct sur les
// routes isolées et départementales, plus dense sur les agglomérations,
// sans en faire trop pour les petites villes » : d'où une ville qui
// double la densité, un village qui l'augmente de moitié seulement.
private _fnFacteur = {
    params ["_pos"];

    private _f = 1;

    if !((nearestLocations [_pos, ["NameCityCapital", "NameCity"], 500]) isEqualTo []) then {
        _f = 3;
    } else {
        if !((nearestLocations [_pos, ["NameVillage"], 400]) isEqualTo []) then {
            _f = 1.8;
        };
    };

    _f
};

// Une position de route dans l'anneau autour d'une grappe. L'anneau se
// mesure sur la grappe, mais la distance minimale vaut pour TOUS les
// joueurs : rien n'apparaît sous le nez de quelqu'un d'autre.
private _fnRouteAutour = {
    params ["_autour", "_min", "_max", "_tous"];

    private _trouve = [];

    for "_essai" from 1 to 12 do {
        private _ancre = selectRandom _autour;
        private _angle = random 360;
        private _d     = _min + random (_max - _min);

        private _p = [
            (getPosATL _ancre select 0) + _d * sin _angle,
            (getPosATL _ancre select 1) + _d * cos _angle,
            0
        ];

        private _routes = _p nearRoads 200;

        if !(_routes isEqualTo []) then {
            private _r = getPos (selectRandom _routes);
            // Jamais plus près que le minimum d'un joueur, même si la
            // route trouvée revient vers lui — et ça vaut pour tous les
            // joueurs, pas seulement ceux de la grappe visée.
            if ([_r, _tous, _min] call _fnLoin) then { _trouve = _r };
        };

        if !(_trouve isEqualTo []) exitWith {};
    };

    _trouve
};

// Un itinéraire qui SUIT la route, au lieu de points tirés au hasard.
//
// La version précédente prenait trois routes au hasard dans un rayon de
// 400 à 1300 m autour du départ. Rien ne garantissait qu'elles soient
// dans le même sens : l'étape 1 pouvait être derrière, l'étape 2 devant,
// l'étape 3 derrière à nouveau. Le véhicule passait son temps à faire
// demi-tour — c'est ça, la conduite erratique.
//
// Ici on part du tronçon de départ et on avance de voisin en voisin,
// sans jamais revenir sur celui d'où l'on vient. Tous les quatorze
// tronçons, on pose une étape. Le trajet est continu et suit vraiment
// le réseau, donc le véhicule a toujours sa route devant lui.
private _fnItineraire = {
    params ["_debut", "_nbEtapes"];

    private _points = [];
    private _routes = _debut nearRoads 30;

    if (_routes isEqualTo []) exitWith { _points };

    private _courant   = _routes select 0;
    private _precedent = objNull;
    private _pas = 0;
    private _max = _nbEtapes * 16;

    while { _pas < _max && { (count _points) < _nbEtapes } } do {

        private _voisins = (roadsConnectedTo _courant) select {
            !(_x isEqualTo _precedent)
        };

        // Cul-de-sac : on s'arrête là, le CYCLE ramènera le véhicule.
        if (_voisins isEqualTo []) exitWith {};

        _precedent = _courant;
        _courant   = selectRandom _voisins;
        _pas = _pas + 1;

        if ((_pas % 14) isEqualTo 0) then { _points pushBack (getPos _courant) };
    };

    _points
};

["INFO", "CIVILS", format [
    "vie civile en service - anneau %1-%2 m, oubli a %3 m",
    _distanceMin, _distanceMax, _distanceOubli
]] call hds_fnc_log;

// ═══════════════════════════════════════════════════════════
// LE CYCLE
// ═══════════════════════════════════════════════════════════
while {true} do {

    private _actif  = missionNamespace getVariable ["hds_civils_actifs", true];
    private _voulu  = round (missionNamespace getVariable ["hds_civils_densite", _densite]);
    private _joueurs = allPlayers select {
        alive _x && { !(_x isKindOf "HeadlessClient_F") }
    };

    // ─── 1. OUBLI ───
    // Réglage décoché, ou plus personne connecté : on vide tout. C'est
    // là que l'économie est maximale, et c'est le cas d'un serveur qui
    // tourne la nuit sans joueurs.
    if (!_actif || { _joueurs isEqualTo [] }) then {

        private _ambiance = call _fnAmbiance;

        if !(_ambiance isEqualTo []) then {
            { [_x] call _fnSupprimer } forEach _ambiance;
            { _x set [2, false] } forEach _lieux;

            ["INFO", "CIVILS", format [
                "%1 civil(s) d'ambiance retire(s) - %2",
                count _ambiance,
                ["aucun joueur connecte", "reglage decoche"] select (!_actif)
            ]] call hds_fnc_log;
        };

    } else {

        {
            if ([_x, _joueurs, _distanceOubli] call _fnLoin) then {
                [_x] call _fnSupprimer;
            };
        } forEach (call _fnAmbiance);

        // Les groupes vidés par le balayage ne servent plus à rien.
        {
            if ((side _x isEqualTo civilian) && { (units _x) isEqualTo [] }) then {
                deleteGroup _x;
            };
        } forEach allGroups;

        // ─── 2. PEUPLER CE DONT ON S'APPROCHE ───
        {
            _x params ["_centre", "_taille", "_peuplee"];

            private _procheAssez = !([_centre, _joueurs, _taille + _distanceMax] call _fnLoin);
            private _desertee    =  [_centre, _joueurs, _taille + _distanceOubli] call _fnLoin;

            if (_procheAssez && { !_peuplee }) then {

                // Le nombre d'habitants était déduit des seules maisons,
                // ratio codé en dur. Le facteur du lieu s'y ajoute
                // maintenant, proportionnellement à la densité demandée :
                // une ville est plus peuplée qu'un hameau, et le curseur
                // du menu agit aussi sur les habitants, pas seulement sur
                // les voitures.
                private _plus = round (_voulu * (([_centre] call _fnFacteur) - 1) / 2);

                // Même population que les chauffeurs : une ville dont
                // les habitants et les automobilistes ne sont pas du
                // même peuple, ça ne va pas.
                [_centre, _plus, _taille, _idCiv, false] spawn fnc_occupations_civil_init;

                // Des voitures vides garées le long des rues : c'est ce
                // qui fait qu'une ville a l'air habitée même quand ses
                // habitants sont rentrés chez eux.
                [_centre, _taille, -1, _idCiv] spawn hds_fnc_voituresGarees;

                _x set [2, true];

                ["INFO", "CIVILS", format [
                    "agglomeration peuplee a l'approche - [%1,%2] r=%3",
                    round (_centre select 0), round (_centre select 1), _taille
                ]] call hds_fnc_log;
            };

            // Les voitures garées portent la même marque que le reste :
            // le balayage les retire dès qu'on s'éloigne du quartier, et
            // rien ne les remplaçait. En traversant une ville, on en
            // voyait donc une au début et plus rien ensuite. On complète
            // à chaque passage, trois par cycle pour étaler le coût.
            if (_peuplee && _procheAssez) then {

                private _cibleGarees = ((round (_taille / 60)) max 2) min 14;

                private _garees = vehicles select {
                    _x getVariable ["hds_civil_ambiance", false]
                    && { alive _x }
                    && { (crew _x) isEqualTo [] }
                    && { (_x distance2D _centre) < (_taille + 50) }
                };

                private _manqueGarees = _cibleGarees - (count _garees);

                if (_manqueGarees > 0) then {
                    [_centre, _taille, _manqueGarees min 3, _idCiv] spawn hds_fnc_voituresGarees;
                };
            };

            // Désertée : l'étape 1 a déjà retiré ses habitants, on note
            // seulement qu'elle est à repeupler à la prochaine visite.
            if (_desertee && { _peuplee }) then { _x set [2, false] };

        } forEach _lieux;

        // ─── 3. COMPLÉTER LE TRAFIC, GRAPPE PAR GRAPPE ───
        // Deux équipes qui opèrent à dix kilomètres l'une de l'autre ne
        // se partagent pas un quota : chacune a le sien. Sinon la
        // seconde roule sur des routes désertes pendant que la première
        // a tout le trafic.
        private _grappes = [_joueurs, 1200] call _fnGrappes;

        {
            _x params ["_ancre", "_equipe"];

            private _cible = round (_voulu * ([_ancre] call _fnFacteur));

            private _ici = vehicles select {
                _x getVariable ["hds_civil_ambiance", false]
                && { alive _x }
                && { !((crew _x) isEqualTo []) }
                && { (_x distance2D _ancre) < _distanceOubli }
            };

            private _manque = _cible - (count _ici);

            // Six par cycle au plus. C'était trois, et avec une cible
            // triplée en ville il fallait près d'une minute pour remplir
            // les rues — d'où un trafic urbain qui paraissait misérable
            // alors qu'il montait seulement trop lentement.
            if (_manque > 0) then {
                for "_i" from 1 to (_manque min 6) do {

                private _depart = [_equipe, _distanceMin, _distanceMax, _joueurs] call _fnRouteAutour;

                if !(_depart isEqualTo []) then {

                    private _veh = createVehicle [
                        selectRandom _classesVeh, _depart, [], 0, "NONE"
                    ];

                    if (!isNull _veh) then {
                        // L'orientation est posée plus bas, une fois
                        // l'itinéraire connu : on la veut dans l'axe de
                        // la route, pas au hasard.
                        _veh setVariable ["hds_civil_ambiance", true, true];

                        private _grp = createGroup [civilian, true];
                        private _chauffeur = _grp createUnit [
                            selectRandom _classesHom, _depart, [], 0, "NONE"
                        ];

                        if (isNull _chauffeur) then {
                            private _n = (units _grp);
                            if !(_n isEqualTo []) then { _chauffeur = _n select 0 };
                        };

                        if (isNull _chauffeur) then {
                            deleteVehicle _veh;
                        } else {
                            _chauffeur setVariable ["hds_civil_ambiance", true, true];
                            _chauffeur moveInDriver _veh;

                            // Les étapes sont sur route, mais entre deux
                            // points le moteur coupe au plus court s'il
                            // y trouve son compte. Un taxi civil qui
                            // traverse un bois, non.
                            if (isOnRoad (getPosATL _veh)) then {
                                _veh forceFollowRoad true;
                            };

                            // Un trajet qui suit le réseau routier.
                            private _etapes = [_depart, 4] call _fnItineraire;

                            if (_etapes isEqualTo []) then { _etapes = [_depart] };

                            {
                                private _wp = _grp addWaypoint [_x, 25];
                                _wp setWaypointType             "MOVE";
                                _wp setWaypointBehaviour        "CARELESS";
                                _wp setWaypointSpeed            "LIMITED";
                                _wp setWaypointCombatMode       "BLUE";
                                _wp setWaypointCompletionRadius 20;
                            } forEach _etapes;

                            private _cycle = _grp addWaypoint [_depart, 25];
                            _cycle setWaypointType             "CYCLE";
                            _cycle setWaypointCompletionRadius 20;

                            _grp setBehaviour  "CARELESS";
                            _grp setSpeedMode  "LIMITED";
                            _grp setCombatMode "BLUE";

                            // Orientée vers sa première étape. Elle
                            // apparaissait avec un cap au hasard, donc
                            // souvent en travers de la chaussée, et
                            // commençait par une manœuvre en trois
                            // temps au milieu de la route.
                            private _cible = _etapes select 0;
                            private _dx = (_cible select 0) - (_depart select 0);
                            private _dy = (_cible select 1) - (_depart select 1);

                            // Pas d'étape exploitable : on s'aligne au
                            // moins sur l'axe du tronçon de départ.
                            if ((_dx * _dx + _dy * _dy) <= 1) then {
                                private _r = _depart nearRoads 30;
                                if !(_r isEqualTo []) then {
                                    private _v = roadsConnectedTo (_r select 0);
                                    if !(_v isEqualTo []) then {
                                        private _p = getPos (_v select 0);
                                        _dx = (_p select 0) - (_depart select 0);
                                        _dy = (_p select 1) - (_depart select 1);
                                    };
                                };
                            };

                            if ((_dx * _dx + _dy * _dy) > 1) then {
                                _veh setDir (((_dx atan2 _dy) + 360) % 360);
                                _veh setVectorUp (surfaceNormal (getPosATL _veh));
                            };

                            _grp enableDynamicSimulation true;
                            _veh enableDynamicSimulation true;
                        };
                    };
                };

                sleep 0.3;
                };
            };

        } forEach _grappes;
    };

    sleep 8;
};
