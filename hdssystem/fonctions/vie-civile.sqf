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

private _classesVeh = [civilian, "LEGER"] call hds_fnc_factionVehicules;
private _classesHom = [civilian] call hds_fnc_factionHommes;

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

// Une position de route dans l'anneau autour d'un joueur.
private _fnRouteAutour = {
    params ["_joueurs", "_min", "_max"];

    private _trouve = [];

    for "_essai" from 1 to 12 do {
        private _ancre = selectRandom _joueurs;
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
            // route trouvée revient vers lui.
            if ([_r, _joueurs, _min] call _fnLoin) then { _trouve = _r };
        };

        if !(_trouve isEqualTo []) exitWith {};
    };

    _trouve
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
                [_centre, 0, _taille, "", false] spawn fnc_occupations_civil_init;
                _x set [2, true];

                ["INFO", "CIVILS", format [
                    "agglomeration peuplee a l'approche - [%1,%2] r=%3",
                    round (_centre select 0), round (_centre select 1), _taille
                ]] call hds_fnc_log;
            };

            // Désertée : l'étape 1 a déjà retiré ses habitants, on note
            // seulement qu'elle est à repeupler à la prochaine visite.
            if (_desertee && { _peuplee }) then { _x set [2, false] };

        } forEach _lieux;

        // ─── 3. COMPLÉTER LE TRAFIC ───
        private _enRoute = (vehicles select {
            _x getVariable ["hds_civil_ambiance", false]
            && { alive _x }
            && { !((crew _x) isEqualTo []) }
        });

        private _manque = _voulu - (count _enRoute);

        // Trois par cycle au plus : une apparition en masse se voit, et
        // tout créer sur la même image fait tressauter le serveur.
        if (_manque > 0) then {
            for "_i" from 1 to (_manque min 3) do {

                private _depart = [_joueurs, _distanceMin, _distanceMax] call _fnRouteAutour;

                if !(_depart isEqualTo []) then {

                    private _veh = createVehicle [
                        selectRandom _classesVeh, _depart, [], 0, "NONE"
                    ];

                    if (!isNull _veh) then {
                        _veh setDir (random 360);
                        _veh setVectorUp (surfaceNormal (getPos _veh));
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

                            // Un itinéraire qui part devant lui plutôt
                            // que de tourner sur place : des routes
                            // prises plus loin, dans n'importe quelle
                            // direction autour du départ.
                            for "_w" from 1 to 3 do {
                                private _routes = _depart nearRoads (400 + random 900);
                                if !(_routes isEqualTo []) then {
                                    private _wp = _grp addWaypoint [
                                        getPos (selectRandom _routes), 40
                                    ];
                                    _wp setWaypointType       "MOVE";
                                    _wp setWaypointBehaviour  "CARELESS";
                                    _wp setWaypointSpeed      "LIMITED";
                                    _wp setWaypointCombatMode "BLUE";
                                };
                            };

                            private _cycle = _grp addWaypoint [_depart, 40];
                            _cycle setWaypointType "CYCLE";

                            _grp enableDynamicSimulation true;
                            _veh enableDynamicSimulation true;
                        };
                    };
                };

                sleep 0.3;
            };
        };
    };

    sleep 8;
};
