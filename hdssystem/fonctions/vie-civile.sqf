/*
 * fnc_hds_vie_civile
 * ─────────────────────────────────────────────────────────────
 * Met de la vie civile sur la carte : des véhicules qui circulent sur
 * les routes, et de la population dans les agglomérations.
 *
 * 0 : <NUMBER> nombre de véhicules civils en circulation
 * 1 : <BOOL>   peupler aussi les villes et villages
 * 2 : <ARRAY>  types de localisation à peupler
 *
 * À lancer avec spawn :
 *   [] spawn fnc_hds_vie_civile;                  // réglages par défaut
 *   [20, true, ["NameCity"]] spawn fnc_hds_vie_civile;
 *
 * ─────────────────────────────────────────────────────────────
 * ── Pourquoi cette fonction existe ──
 * La case « Trafic civil sur les routes » du générateur émettait
 * « [] spawn fnc_engima_traffic ». C'est le script tiers d'Engima :
 * il n'est pas dans ce dépôt, et l'installer ajouterait une
 * dépendance alors que tout le travail de ces derniers temps a
 * consisté à n'avoir plus que CBA_A3 comme prérequis. Cocher la case
 * produisait donc une variable indéfinie, qui avorte le scénario.
 *
 * Le registre de factions sait déjà tout ce qu'il faut : le scan de
 * CfgVehicles range aussi les véhicules de camp civil (side 3), et le
 * scan des civils range leurs hommes. On n'a donc besoin de rien
 * d'autre que de ce qui est déjà là.
 *
 * ── Ce qu'elle fait, précisément ──
 * Le trafic : des positions de route tirées au hasard sur toute la
 * carte, un véhicule léger civil et son chauffeur à chacune, puis
 * quatre points de passage et un CYCLE. Comportement CARELESS et
 * allure LIMITED : ils roulent, ils ne font pas la guerre.
 *
 * La population : fnc_occupations_civil_init sur chaque localisation
 * retenue, qui place des casaniers assis chez eux et des piétons. Le
 * nombre d'habitants y est déduit du nombre de maisons.
 *
 * Les deux respectent le réglage CBA « Population civile »
 * (hds_civils_actifs) : décoché, cette fonction ne place rien.
 */

if (!isServer) exitWith {};

params [
    ["_nbVehicules",      12],
    ["_peupler",          true],
    ["_typeLocalisation", ["NameCity", "NameVillage"]]
];

if (!canSuspend) exitWith {
    ["ERREUR", "CIVILS", "fnc_hds_vie_civile doit etre lancee avec spawn, pas call"]
        call hds_fnc_log;
};

if !(missionNamespace getVariable ["hds_civils_actifs", true]) exitWith {
    ["INFO", "CIVILS", "vie civile desactivee par le reglage CBA - rien de place"]
        call hds_fnc_log;
};

// Le registre est rempli de façon asynchrone au démarrage.
if (!hds_factions_pret) then { waitUntil { hds_factions_pret } };

// ═══════════════════════════════════════════════════════════
// UNE POSITION DE ROUTE, N'IMPORTE OÙ SUR LA CARTE
// ═══════════════════════════════════════════════════════════
// Tirer un point au hasard puis chercher la route la plus proche coûte
// beaucoup moins cher qu'un « nearRoads worldSize » depuis le centre,
// qui ramène tous les segments de la carte d'un coup. Et ça répartit
// le trafic au lieu de l'empiler.
//
// exitWith dans un for sort bien de la boucle — c'est le comportement
// voulu ici, contrairement à un forEach où il faut un if/then.
private _posRoute = {
    private _trouve = [];
    for "_essai" from 1 to 15 do {
        private _routes = [random worldSize, random worldSize, 0] nearRoads 700;
        if !(_routes isEqualTo []) then {
            _trouve = getPos (selectRandom _routes);
        };
        if !(_trouve isEqualTo []) exitWith {};
    };
    _trouve
};

// ═══════════════════════════════════════════════════════════
// TRAFIC
// ═══════════════════════════════════════════════════════════
private _classesVeh = [civilian, "LEGER"] call hds_fnc_factionVehicules;
private _classesHom = [civilian] call hds_fnc_factionHommes;

private _poses = 0;

if (_classesVeh isEqualTo [] || { _classesHom isEqualTo [] }) then {
    ["ALERTE", "CIVILS", format [
        "pas de trafic : %1 vehicule(s) civil(s) et %2 homme(s) civil(s) dans le registre",
        count _classesVeh, count _classesHom
    ]] call hds_fnc_log;
} else {

    for "_i" from 1 to _nbVehicules do {

        private _depart = call _posRoute;

        if (_depart isEqualTo []) then {
            ["ALERTE", "CIVILS", "aucune route trouvee pour ce vehicule - ignore"]
                call hds_fnc_log;
        } else {

            private _veh = createVehicle [selectRandom _classesVeh, _depart, [], 0, "NONE"];

            if (isNull _veh) then {
                ["ALERTE", "CIVILS", "vehicule civil non cree - ignore"] call hds_fnc_log;
            } else {

                _veh setDir (random 360);
                _veh setVectorUp (surfaceNormal (getPos _veh));

                private _grp = createGroup civilian;
                private _chauffeur = _grp createUnit [
                    selectRandom _classesHom, _depart, [], 0, "NONE"
                ];
                _chauffeur moveInDriver _veh;

                // Les étapes sont déjà sur route, mais entre deux points
                // le moteur coupe au plus court s'il y trouve son
                // compte. Un taxi civil qui traverse un bois, non.
                if (isOnRoad (getPosATL _veh)) then { _veh forceFollowRoad true };

                // ─── Itinéraire ───
                for "_w" from 1 to 4 do {
                    private _etape = call _posRoute;
                    if !(_etape isEqualTo []) then {
                        private _wp = _grp addWaypoint [_etape, 30];
                        _wp setWaypointType        "MOVE";
                        _wp setWaypointBehaviour   "CARELESS";
                        _wp setWaypointSpeed       "LIMITED";
                        _wp setWaypointCombatMode  "BLUE";
                    };
                };

                // CYCLE sur le départ : ils tournent indéfiniment, sans
                // qu'on ait à les suivre ni à les nettoyer.
                private _cycle = _grp addWaypoint [_depart, 30];
                _cycle setWaypointType "CYCLE";

                _grp enableDynamicSimulation true;

                _poses = _poses + 1;
            };
        };

        // Étaler : un véhicule par image au plus, sinon le démarrage gèle.
        sleep 0.5;
    };

    ["INFO", "CIVILS", format [
        "%1 vehicule(s) civil(s) en circulation sur %2 demande(s) - %3 classes disponibles",
        _poses, _nbVehicules, count _classesVeh
    ]] call hds_fnc_log;
};

// ═══════════════════════════════════════════════════════════
// POPULATION
// ═══════════════════════════════════════════════════════════
if (_peupler) then {

    private _localisations = nearestLocations [
        [worldSize / 2, worldSize / 2, 0],
        _typeLocalisation,
        worldSize
    ];

    if (_localisations isEqualTo []) then {
        ["ALERTE", "CIVILS", format [
            "aucune localisation de type %1 sur %2 - rien a peupler",
            _typeLocalisation, worldName
        ]] call hds_fnc_log;
    } else {

        ["INFO", "CIVILS", format [
            "%1 agglomeration(s) a peupler", count _localisations
        ]] call hds_fnc_log;

        {
            // Le rayon suit le lieu : une ville mérite plus large qu'un
            // hameau. Attention, « size » sur une Location rend un
            // TABLEAU [x, y], pas un nombre — on prend le plus grand
            // des deux côtés, borné pour éviter l'extrême dans les deux
            // sens.
            private _dim = size _x;
            private _taille = 300;
            if (_dim isEqualType [] && { count _dim >= 2 }) then {
                _taille = ((((_dim select 0) max (_dim select 1)) * 2) max 150) min 600;
            };

            [locationPosition _x, 0, _taille, "", false] spawn fnc_occupations_civil_init;

            sleep 1;
        } forEach _localisations;
    };
};

["INFO", "CIVILS", "vie civile en place"] call hds_fnc_log;

true
