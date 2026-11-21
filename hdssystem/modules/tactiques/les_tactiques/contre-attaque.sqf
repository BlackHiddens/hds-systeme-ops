/*
 * fnc_tactique_contreattaque
 * ─────────────────────────────────────────────────────────────
 * Lance une contre-attaque sur une position : des groupes
 * d'infanterie et des véhicules convergent depuis la périphérie.
 *
 * 0 : <ARRAY>               position visée
 * 1 : <NUMBER>              nombre de groupes d'infanterie
 * 2 : <NUMBER>              nombre de véhicules
 * 3 : <NUMBER>              distance de départ (m)
 * 4 : <NUMBER|STRING|SIDE>  faction
 * 5 : <BOOL>                marquer la cible sur la carte
 *
 * À lancer avec spawn :
 *   [_pos, 2, 2, 700, east, false] spawn fnc_tactique_contreattaque;
 */

params [
    ["_pos",              [0,0,0]],
    ["_nbgroupeinf",      2],
    ["_nbvehicule",       2],
    ["_distanceapproche", 700],
    ["_camps",            east],
    ["_ciblemarqueur",    false]
];

if (hdssysteme) then {
    [format ["%1 : Mission rechercher et détruire donnée à des groupes d'infanterie", hdstactiqueversion]]
        remoteExecCall ["systemChat", 0];
};

if (!hds_factions_pret) then {
    if (canSuspend) then { waitUntil { hds_factions_pret } };
};

([_camps] call hds_fnc_factionResoudre) params ["_id", "_side"];

// Assaut : on cherche du volume (section, puis squad, puis fireteam)
private _groupe    = [_id, "ASSAUT"]      call hds_fnc_factionGroupe;
private _vehicules = [_id, "PATROUILLE"]  call hds_fnc_factionVehicules;

if (isNull _groupe) exitWith {
    diag_log format ["[HDS][TACTIQUES] Contre-attaque impossible pour %1 : aucun groupe", _id];
};

// Sans véhicule disponible, l'assaut part à pied
if (_vehicules isEqualTo []) then {
    diag_log format ["[HDS][TACTIQUES] %1 : aucun vehicule — contre-attaque a pied", _id];
    _nbvehicule = 0;
};

private _custom_distance_approche = _distanceapproche * 2;

if (hdssysteme) then {
    diag_log format [
        "[HDS][TACTIQUES] Contre-attaque %1 [%2] — %3 x%4 inf, %5 vehicule(s) parmi %6 classes",
        _id, _side, configName _groupe, _nbgroupeinf, _nbvehicule, count _vehicules
    ];
};

[
    ([_pos, _custom_distance_approche, (_custom_distance_approche + 150), 1, 0, 60] call BIS_fnc_findSafePos),
    _groupe,
    _custom_distance_approche,
    _side,
    _nbgroupeinf,
    _vehicules,
    _nbvehicule
] spawn fnc_tactique_groupedecombat;
