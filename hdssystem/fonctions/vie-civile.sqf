/*
 * fnc_hds_vie_civile
 * ─────────────────────────────────────────────────────────────
 * Vie civile : les habitants des agglomérations proches et les voitures
 * garées le long des rues. Le trafic routier, lui, est confié au script
 * d'Engima.
 *
 * 0 : <NUMBER> densité (habitants, et compte de départ du trafic)
 * 1 : <BOOL>   peupler aussi les agglomérations proches
 * 2 : <ARRAY>  types de localisation à peupler
 * 3 : <NUMBER> conservé pour les anciens appels, sans effet
 * 4 : <NUMBER> distance d'approche d'une agglomération (m)
 * 5 : <NUMBER> distance d'oubli des habitants (m)
 *
 * À lancer avec spawn :
 *   [] spawn fnc_hds_vie_civile;
 *
 * ─────────────────────────────────────────────────────────────
 * ── Le trafic, c'est Engima, et c'est un retour en arrière assumé ──
 * J'avais remplacé son script par du code maison, au motif qu'il
 * n'était pas dans le dossier de mission. Il était en fait dans
 * l'historique du dépôt, d'où il a été récupéré.
 *
 * Après plusieurs tentatives, mon remplacement restait nettement moins
 * bon : routes vides, véhicules qui manœuvrent sur place. Ce que son
 * script fait et que je n'avais pas reproduit :
 *
 *   - il entretient ses véhicules DANS le voisinage immédiat du joueur
 *     et supprime tout ce qui dépasse sa distance d'apparition ;
 *   - il vise un point en avant du joueur, pas un cercle autour ;
 *   - il connaît les tronçons de bord de carte et les coins ;
 *   - il surveille les véhicules immobiles depuis plus d'une minute
 *     pour les reprendre.
 *
 * C'est des années de mise au point. Je n'allais pas les refaire en une
 * journée, et il n'y avait aucune raison d'essayer.
 *
 * Seul changement apporté à son code : sa liste de véhicules vient du
 * registre de factions au lieu d'une liste de classnames codée en dur
 * qui n'existe plus. Voir engima/Traffic/ConfigAndStart.sqf.
 *
 * ── Ce que cette fonction garde ──
 * Les habitants et les voitures garées, entretenus autour des joueurs
 * par un cycle de huit secondes :
 *
 *   1. OUBLI    tout civil d'ambiance dont le joueur le plus proche est
 *               au-delà de la distance d'oubli est supprimé. Plus
 *               personne connecté : on vide.
 *   2. PEUPLER  une agglomération dont un joueur s'approche reçoit sa
 *               population. On regarde ce qui reste réellement sur
 *               place, pas un drapeau : une ville qu'on traverse se vide
 *               derrière soi et doit se repeupler.
 *   3. GARER    des voitures vides le long des rues habitées,
 *               complétées au fil des passages.
 *
 * Seuls les civils marqués « hds_civil_ambiance » sont balayés. Un
 * otage, un VIP, un civil posé par une mission, et les véhicules
 * d'Engima — qui gère les siens — ne portent pas cette marque.
 *
 * Le réglage CBA « Population civile » décoché arrête tout.
 */

if (!isServer) exitWith {};

params [
    ["_densite",          8],
    ["_peupler",          true],
    ["_typeLocalisation", ["NameCity", "NameVillage"]],
    ["_inutilise",        300],
    ["_distanceApproche", 500],
    ["_distanceOubli",    1400]
];

if (!canSuspend) exitWith {
    ["ERREUR", "CIVILS", "fnc_hds_vie_civile doit etre lancee avec spawn, pas call"]
        call hds_fnc_log;
};

// Le registre est rempli de façon asynchrone au démarrage.
if (!hds_factions_pret) then { waitUntil { hds_factions_pret } };

// ─── Une seule faction civile, pour tout ───
// Les habitants, les voitures garées et le trafic d'Engima tirent leurs
// classes du même id : une ville dont les passants et les automobilistes
// ne sont pas du même peuple, ça se remarque.
([civilian] call hds_fnc_factionResoudre) params ["_idCiv", "_sideCiv"];

private _classesHom = [_idCiv] call hds_fnc_factionHommes;

["INFO", "CIVILS", format [
    "population civile retenue : %1 - %2 homme(s) dans le registre",
    (["aucune", _idCiv] select (_idCiv != "")), count _classesHom
]] call hds_fnc_log;

if (isNil "hds_civils_densite") then { hds_civils_densite = _densite };
if (isNil "hds_civils_portee")  then { hds_civils_portee  = _distanceApproche };

// ═══════════════════════════════════════════════════════════
// LE TRAFIC : ON PASSE LA MAIN
// ═══════════════════════════════════════════════════════════
if (missionNamespace getVariable ["hds_civils_actifs", true]) then {
    if (isNil "fnc_engima_traffic") then {
        ["ALERTE", "CIVILS",
         "trafic : le script Engima n'est pas charge - aucune circulation"
        ] call hds_fnc_log;
    } else {
        [] spawn fnc_engima_traffic;
    };
};

// ═══════════════════════════════════════════════════════════
// LES AGGLOMÉRATIONS, RELEVÉES UNE SEULE FOIS
// ═══════════════════════════════════════════════════════════
// [centre, rayon, peuplée, routes bordées de maisons (-1 inconnu),
//  instant avant lequel on ne repeuple pas]
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

        _lieux pushBack [locationPosition _x, _taille, false, -1, 0];
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

// Plus peuplé en ville qu'à la campagne.
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

// ═══════════════════════════════════════════════════════════
// LE CYCLE : HABITANTS ET VOITURES GARÉES
// ═══════════════════════════════════════════════════════════
while {true} do {

    private _actif   = missionNamespace getVariable ["hds_civils_actifs", true];
    private _voulu   = round (missionNamespace getVariable ["hds_civils_densite", _densite]);
    private _joueurs = allPlayers select {
        alive _x && { !(_x isKindOf "HeadlessClient_F") }
    };

    private _approche = round (missionNamespace getVariable ["hds_civils_portee", _distanceApproche]);
    if (_approche < 120) then { _approche = 120 };

    // ─── 1. OUBLI ───
    if (!_actif || { _joueurs isEqualTo [] }) then {

        private _ambiance = call _fnAmbiance;

        if !(_ambiance isEqualTo []) then {
            { [_x] call _fnSupprimer } forEach _ambiance;
            { _x set [2, false]; _x set [4, 0] } forEach _lieux;

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

        // ─── 2. PEUPLER, ET SURTOUT REPEUPLER ───
        {
            private _lieu = _x;
            _lieu params ["_centre", "_taille", "_peuplee", "_routesOk", "_prochain"];

            private _procheAssez = !([_centre, _joueurs, _taille + _approche] call _fnLoin);
            private _desertee    =  [_centre, _joueurs, _taille + _distanceOubli] call _fnLoin;

            if (_procheAssez) then {

                // Combien d'habitants d'ambiance restent réellement là.
                private _habitants = allUnits select {
                    _x getVariable ["hds_civil_ambiance", false]
                    && { alive _x }
                    && { (_x distance2D _centre) < (_taille + 60) }
                };

                // Une ville qu'on traverse se vide derrière soi : le
                // balayage retire ses habitants au fur et à mesure qu'on
                // les dépasse. On regarde donc ce qui reste sur place,
                // pas un drapeau posé une fois pour toutes.
                if ((!_peuplee || { (count _habitants) < 5 }) && { time >= _prochain }) then {

                    private _plus = round (_voulu * (([_centre] call _fnFacteur) - 1) / 2);

                    [_centre, _plus, _taille, _idCiv, false] spawn fnc_occupations_civil_init;

                    _lieu set [2, true];
                    _lieu set [4, time + 45];

                    ["INFO", "CIVILS", format [
                        "agglomeration %1 - [%2,%3] r=%4, %5 habitant(s) encore sur place",
                        (["peuplee", "repeuplee"] select _peuplee),
                        round (_centre select 0), round (_centre select 1),
                        round _taille, count _habitants
                    ]] call hds_fnc_log;
                };

                // ─── 3. VOITURES GARÉES ───
                // _routesOk retient s'il y a seulement des routes bordées
                // de maisons ici : sans ça, un village qui n'en a aucune
                // relançait un nearRoads complet à chaque cycle.
                if (_routesOk != 0) then {

                    if (_routesOk < 0) then {
                        private _rh = (_centre nearRoads _taille) select {
                            (count (nearestObjects [getPos _x, ["House"], 60])) > 0
                        };
                        _routesOk = [0, 1] select ((count _rh) > 0);
                        _lieu set [3, _routesOk];
                    };

                    if (_routesOk isEqualTo 1) then {

                        private _cibleGarees = ((round (_taille / 60)) max 2) min 14;

                        private _garees = vehicles select {
                            _x getVariable ["hds_civil_ambiance", false]
                            && { alive _x }
                            && { (crew _x) isEqualTo [] }
                            && { (_x distance2D _centre) < (_taille + 50) }
                        };

                        private _manqueGarees = _cibleGarees - (count _garees);

                        if (_manqueGarees > 0) then {
                            [_centre, _taille, _manqueGarees min 3, _idCiv]
                                spawn hds_fnc_voituresGarees;
                        };
                    };
                };
            };

            // Désertée : elle se repeuplera à la prochaine visite.
            if (_desertee && { _peuplee }) then { _lieu set [2, false] };

        } forEach _lieux;
    };

    sleep 8;
};
