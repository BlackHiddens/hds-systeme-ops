/*
 * Paramètres de l'instance de trafic, et démarrage.
 * C'est le fichier prévu pour être édité : tout le reste du dossier
 * Engima est du code tiers qu'on ne touche pas.
 *
 * ── Qui décide ici ──
 * Personne, ou presque. Engima n'est pas exposé au scénario : il est
 * piloté par fnc_hds_vie_civile, qui pose hds_vie_densite,
 * hds_vie_portee et hds_vie_plafond à partir des paramètres écrits dans
 * init-scenario.sqf. Ce fichier ne fait que les relayer.
 *
 * Les valeurs de repli entre crochets ne servent que si quelqu'un
 * démarre le trafic sans passer par fnc_hds_vie_civile : on retombe
 * alors sur les curseurs CBA, puis sur les réglages d'origine du script
 * (5 véhicules, 300-500 m).
 *
 * ── Ce qui a changé par rapport à l'original ──
 * La liste de véhicules était hds_liste_vehicule_civil_europeens, une
 * des listes de classnames codées en dur qui ont disparu avec la
 * réécriture. En SQF, une variable indéfinie n'échoue pas sur sa ligne —
 * elle avorte tout le script. Le trafic n'aurait donc pas démarré du
 * tout.
 *
 * Elle vient maintenant du registre de factions, qui ne contient que ce
 * que ce serveur a réellement : la liste s'adapte aux mods présents, et
 * ne contient jamais une classe absente.
 */

private _classes = [civilian, "LEGER"] call hds_fnc_factionVehicules;

if (_classes isEqualTo []) exitWith {
    ["ALERTE", "CIVILS",
     "trafic Engima : aucun vehicule civil dans le registre - trafic non demarre"
    ] call hds_fnc_log;
};

// ─── Portée : le scénario, sinon le curseur, sinon l'origine ───
private _portee = round (missionNamespace getVariable [
    "hds_vie_portee",
    missionNamespace getVariable ["hds_civils_portee", 500]
]);
if (_portee < 120) then { _portee = 120 };

private _nb = round (missionNamespace getVariable [
    "hds_vie_densite",
    missionNamespace getVariable ["hds_civils_densite", 5]
]);
if (_nb < 0) then { _nb = 0 };

// MAX_GROUPS_COUNT est calculé une seule fois, au démarrage, à partir de
// VEHICLES_COUNT. Comme le compte varie ensuite en cours de partie —
// fnc_hds_vie_civile le monte quand les joueurs entrent en ville — il
// faut lui donner d'emblée la marge haute, sinon il plafonnerait à la
// valeur de départ.
private _plafond = round (missionNamespace getVariable ["hds_vie_plafond", _nb max 14]);

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
    "trafic Engima demarre : %1 vehicule(s) vises (plafond %2), anneau %3-%4 m, %5 classe(s) civiles",
    _nb, _plafond, round (_portee * 0.6), _portee, count _classes
]] call hds_fnc_log;

_parameters spawn ENGIMA_TRAFFIC_StartTraffic;
