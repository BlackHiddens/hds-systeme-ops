/*
 * fnc_hds_occupations
 * ─────────────────────────────────────────────────────────────
 * Occupe une zone : garnisons dans les bâtiments, patrouilles à pied,
 * patrouilles motorisées.
 *
 * 0 : <ARRAY>              centre de la zone
 * 1 : <NUMBER>             nombre d'équipes par type (densité)
 * 2 : <NUMBER|STRING|SIDE> faction
 * 3 : <NUMBER>             rayon de la zone (m)
 * 4 : <BOOL>               marqueur de zone visible sur la carte
 *
 * Le paramètre faction accepte trois formes :
 *   0..7              ancien index HDS — conservé pour tout le code
 *                     existant et pour le générateur web
 *   "OPF_F"           un id de faction du registre
 *   east / "AUTO"     déduit la faction de ce que la mission a posé
 *                     dans l'éditeur
 *
 * Plus aucun classname ni chemin CfgGroups en dur : les compositions
 * viennent du registre (hdssystem\modules\factions\), qui ne contient
 * que ce que ce serveur a réellement. Une faction absente retombe sur
 * une faction du même camp au lieu de ne rien produire.
 *
 * À lancer avec spawn :
 *   [_centre, 1, east, 500, false] spawn fnc_hds_occupations;
 */

params [
    ["_centre",  [0,0,0]],
    ["_ratio",   1],
    ["_faction", east],
    ["_taille",  500],
    ["_visible", false]
];

if (!isServer) exitWith {};

// ─── Le registre est rempli de façon asynchrone au démarrage ───
if (!hds_factions_pret) then {
    if (canSuspend) then {
        waitUntil { hds_factions_pret };
    } else {
        diag_log "[HDS][OCCUPATIONS] /!\ Appel en unscheduled avant la fin du scan — utiliser spawn";
    };
};

// ─── Résolution de la faction ───
([_faction] call hds_fnc_factionResoudre) params ["_id", "_side"];

if (_id isEqualTo "") exitWith {
    diag_log format [
        "[HDS][OCCUPATIONS] Aucune faction disponible pour %1 — occupation annulee",
        _faction
    ];
};

// ─── Compositions : la liste complète, pour varier d'une équipe à l'autre ───
private _garnisons   = [_id, "GARNISON"]   call hds_fnc_factionGroupes;
private _patrouilles = [_id, "PATROUILLE"] call hds_fnc_factionGroupes;
private _vehicules   = [_id, "PATROUILLE"] call hds_fnc_factionVehicules;

if (hdssysteme) then {
    diag_log format [
        "[HDS][OCCUPATIONS] %1 [%2] @ [%3,%4] r=%5 densite=%6 — %7 garnisons / %8 patrouilles / %9 vehicules",
        _id, _side,
        round (_centre select 0), round (_centre select 1),
        _taille, _ratio,
        count _garnisons, count _patrouilles, count _vehicules
    ];
};

// ─── Combien d'équipes en garnison ? ───
// La densité demandée convient pour un champ, pas pour un village : si
// la zone a des bâtiments, il faut du monde dedans, sinon l'occupation
// ne se voit pas. On compte les places réellement disponibles et on en
// vise environ la moitié.
//
// _ratio reste le plancher — on ne met jamais moins que ce qui est
// demandé — et deux plafonds évitent de vider le serveur sur une
// grande ville : quatre fois la densité demandée, et 12 équipes.
private _nbPlaces = 0;
{
    _nbPlaces = _nbPlaces + count ([_x, -1] call CBA_fnc_buildingPositions);
} forEach ((nearestObjects [_centre, ["Building"], _taille]) select { alive _x });

private _equipesGarnison = _ratio;
if (_nbPlaces > 0) then {
    // une équipe fait ~8 hommes, on veut remplir une place sur deux
    _equipesGarnison = ((round (_nbPlaces / 16)) max _ratio) min (_ratio * 4) min 12;
};

if (hdssysteme) then {
    ["INFO", "OCCUPATIONS", format [
        "%1 places de batiment dans %2 m -> %3 equipes en garnison (densite demandee %4)",
        _nbPlaces, _taille, _equipesGarnison, _ratio
    ]] call hds_fnc_log;
};

// ─── Mise en place ───
if (count _garnisons > 0) then {
    [_centre, _taille, _equipesGarnison, _garnisons, 0, _side, _visible] call fnc_occupations_init;
} else {
    diag_log format ["[HDS][OCCUPATIONS] %1 : aucune composition de garnison", _id];
};

// ─── Tours de guet ───
// Les bâtiments ordinaires gardent le calcul au ratio. Les tours, non :
// une tour de guet vide ne sert à rien, donc au moins un homme dans
// chacune, en plus de la garnison. À défaut de composition de
// garnison, on prend les classes des patrouilles.
private _pourTours = if (count _garnisons > 0) then { _garnisons } else { _patrouilles };

if (count _pourTours > 0) then {
    [_centre, _taille, _side, _pourTours] call hds_fnc_miradors;
};

if (count _patrouilles > 0) then {
    [_centre, _taille, _ratio, _patrouilles, 1, _side, _visible] call fnc_occupations_init;
} else {
    diag_log format ["[HDS][OCCUPATIONS] %1 : aucune composition de patrouille", _id];
};

if (count _vehicules > 0) then {
    [_centre, _taille, _ratio, _vehicules, 2, _side, _visible] call fnc_occupations_init;
} else {
    diag_log format ["[HDS][OCCUPATIONS] %1 : aucun vehicule de patrouille", _id];
};

true
