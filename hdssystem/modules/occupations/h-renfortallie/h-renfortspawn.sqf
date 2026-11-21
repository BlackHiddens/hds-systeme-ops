/*
 * fnc_hds_renfortSpawn
 * ─────────────────────────────────────────────────────────────
 * Fait apparaître un renfort allié et l'habille comme les joueurs.
 *
 * 0 : <ARRAY>  position visée
 * 1 : <SIDE>   camp du renfort
 * 2 : <OBJECT> le demandeur (pour le regroupement), objNull si aucun
 * 3 : <BOOL>   les hommes rejoignent le groupe du demandeur
 * 4 : <NUMBER> distance d'apparition minimale (défaut 450)
 * 5 : <NUMBER> distance d'apparition maximale (défaut 650)
 * 6 : <STRING> intention ou rôle demandé au registre (défaut ASSAUT)
 *
 * Retourne : <GROUP> le groupe créé, grpNull si rien n'était possible
 *
 * CÔTÉ SERVEUR UNIQUEMENT. Les points d'entrée côté client passent par
 * remoteExec vers la machine 2.
 *
 * Deux raisons à ça. Le registre de factions n'existe que sur le
 * serveur, puisqu'il est construit depuis init-systeme.sqf. Et un
 * BIS_fnc_spawnGroup lancé par un client crée un groupe local à ce
 * client, ce que faisait l'ancienne version : en multijoueur, ces
 * renforts n'appartenaient pas au serveur.
 *
 * Le groupe vient du registre, donc sa composition est celle d'une
 * faction réellement installée. Son équipement est copié des joueurs
 * quand il y en a — sinon il garde celui de sa faction, déjà cohérent.
 */

if (!isServer) exitWith { grpNull };

params [
    ["_pos",        [0,0,0]],
    ["_camp",       west],
    ["_demandeur",  objNull],
    ["_rejoindre",  false],
    ["_distMin",    450],
    ["_distMax",    650],
    ["_intention",  "ASSAUT"]
];

if (!hds_factions_pret) then {
    if (canSuspend) then { waitUntil { hds_factions_pret } };
};

// ─── Composition ───
private _cfg = [_camp, _intention] call hds_fnc_factionGroupe;

if (isNull _cfg) exitWith {
    ["ALERTE", "RENFORT", format [
        "Aucune composition %1 disponible pour le camp %2", _intention, _camp
    ]] call hds_fnc_log;
    grpNull
};

// ─── Apparition ───
private _depart = [_pos, _distMin, _distMax, 1, 0, 60, 0] call BIS_fnc_findSafePos;
private _grp = [_depart, _camp, _cfg] call BIS_fnc_spawnGroup;

if (isNull _grp) exitWith {
    ["ALERTE", "RENFORT", format ["spawnGroup a echoue pour %1", configName _cfg]] call hds_fnc_log;
    grpNull
};

// ─── Tenue copiée des joueurs ───
[_grp, _camp] call fnc_hds_equiperCommeJoueurs;

// ─── Mise en route ───
_grp addWaypoint [_pos, 0];
_grp enableDynamicSimulation true;

if (_rejoindre && { !isNull _demandeur }) then {
    // joinSilent exécuté là où les hommes sont locaux, donc ici
    (units _grp) joinSilent (group _demandeur);
};

["INFO", "RENFORT", format [
    "%1 (%2 h) depuis [%3,%4] vers [%5,%6]%7",
    configName _cfg, count (units _grp),
    round (_depart select 0), round (_depart select 1),
    round (_pos select 0), round (_pos select 1),
    (["", " - rejoint le demandeur"] select _rejoindre)
]] call hds_fnc_log;

_grp
