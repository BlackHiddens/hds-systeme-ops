/*
 * Paramètres de l'instance de trafic, et démarrage.
 * C'est le fichier prévu pour être édité : tout le reste du dossier
 * Engima est du code tiers qu'on ne touche pas.
 *
 * ── Ce qui a changé par rapport à l'original ──
 * Une seule chose, et par nécessité : la liste de véhicules était
 * hds_liste_vehicule_civil_europeens, une des listes de classnames
 * codées en dur qui ont disparu avec la réécriture. En SQF, une
 * variable indéfinie n'échoue pas sur sa ligne — elle avorte tout le
 * script. Le trafic n'aurait donc pas démarré du tout.
 *
 * Elle vient maintenant du registre de factions, qui ne contient que ce
 * que ce serveur a réellement : la liste s'adapte aux mods présents, et
 * ne contient jamais une classe absente.
 *
 * Le nombre de véhicules et les distances sont repris des réglages du
 * menu CBA, avec les valeurs d'origine par défaut (5 véhicules,
 * 300-500 m). Attention : Engima lit ses paramètres UNE FOIS, au
 * démarrage. Changer les curseurs en cours de partie n'agit donc pas
 * sur le trafic, seulement sur les habitants et les voitures garées.
 */

private _classes = [civilian, "LEGER"] call hds_fnc_factionVehicules;

if (_classes isEqualTo []) exitWith {
    ["ALERTE", "CIVILS",
     "trafic Engima : aucun vehicule civil dans le registre - trafic non demarre"
    ] call hds_fnc_log;
};

private _portee = round (missionNamespace getVariable ["hds_civils_portee", 500]);
if (_portee < 120) then { _portee = 120 };

private _nb = round (missionNamespace getVariable ["hds_civils_densite", 5]);
if (_nb < 0) then { _nb = 0 };

// MAX_GROUPS_COUNT est calculé au démarrage à partir de VEHICLES_COUNT.
// Comme le compte varie maintenant en cours de partie, on lui donne
// d'emblée la marge haute, sinon il plafonnerait à la valeur de départ.
private _plafond = 14;

private _parameters = [
    ["SIDE",               civilian],
    ["VEHICLES",           _classes],
    ["VEHICLES_COUNT",     _nb],
    ["MAX_GROUPS_COUNT",   _plafond],
    ["MIN_SPAWN_DISTANCE", round (_portee * 0.6)],
    ["MAX_SPAWN_DISTANCE", _portee],
    ["MIN_SKILL",          1],
    ["MAX_SKILL",          1],
    ["DEBUG",              hds_engima_debugg],

    // ── Ses propres points d'accroche, pas une modification ──
    // Sans ça, impossible de savoir depuis le journal s'il ne fait rien
    // apparaitre ou si ce qu'il pose disparait aussitot. Il prevoit ces
    // callbacks, autant s'en servir.
    ["ON_UNIT_CREATED", {
        params ["_veh", "_grp", "_actifs", "_vises"];
        ["INFO", "CIVILS", format [
            "trafic : %1 cree - %2 actif(s) sur %3 vises",
            typeOf _veh, _actifs, _vises
        ]] call hds_fnc_log;
    }],

    ["ON_UNIT_REMOVING", {
        params ["_veh", "_grp", "_actifs", "_vises"];
        ["INFO", "CIVILS", format [
            "trafic : %1 retire - %2 actif(s) sur %3 vises",
            typeOf _veh, _actifs, _vises
        ]] call hds_fnc_log;
    }]
];

["INFO", "CIVILS", format [
    "trafic Engima demarre : %1 vehicule(s) vises, anneau %2-%3 m, %4 classe(s) civiles",
    _nb, round (_portee * 0.6), _portee, count _classes
]] call hds_fnc_log;

_parameters spawn ENGIMA_TRAFFIC_StartTraffic;
