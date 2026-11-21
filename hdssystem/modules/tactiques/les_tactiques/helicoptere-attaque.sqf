/*
 * fnc_tactique_appuihelico
 * ─────────────────────────────────────────────────────────────
 * Met en place un appui aérien : un hélicoptère armé qui patrouille
 * autour d'un joueur tiré au sort.
 *
 * 0 : <ARRAY|STRING>        position, ou nom de marqueur
 * 1 : <NUMBER>              distance d'approche (m)
 * 2 : <NUMBER|STRING|SIDE>  faction
 *
 * Repli en trois temps, tracé dans le RPT :
 *   1. hélicoptère armé de la faction
 *   2. à défaut, hélicoptère de transport (il est armé de ses portes
 *      ou sert au moins de présence aérienne)
 *   3. à défaut, appui terrestre : un groupe en véhicule
 *
 * L'ancienne version donnait un appui aérien à quatre factions sur
 * huit. Les trois factions Project OPFOR recevaient un camion, et la
 * FIA un hélicoptère civil désarmé. Le repli était là, mais déguisé
 * en choix délibéré.
 *
 * À lancer avec spawn :
 *   [_pos, 800, east] spawn fnc_tactique_appuihelico;
 */

params [["_position", [0,0,0]], ["_distanceproche", 800], ["_camps", east]];

if (hdssysteme) then {
    [format ["%1 : Mise en place d'un appui dans le secteur", hdstactiqueversion]]
        remoteExecCall ["systemChat", 0];
};

if (!hds_factions_pret) then {
    if (canSuspend) then { waitUntil { hds_factions_pret } };
};

([_camps] call hds_fnc_factionResoudre) params ["_id", "_side"];

// ─── 1) et 2) voie aérienne ───
private _helico = [_id, "HELICO_ARME"] call hds_fnc_factionVehicule;

if (_helico != "") exitWith {
    if (hdssysteme) then {
        diag_log format ["[HDS][TACTIQUES] Appui aerien %1 [%2] — %3", _id, _side, _helico];
    };
    [_position, _helico, _distanceproche, _side] spawn fnc_tactique_helicocombat;
};

// ─── 3) repli terrestre ───
private _groupe = [_id, "PATROUILLE"] call hds_fnc_factionGroupe;
private _vehic  = [_id, "PATROUILLE"] call hds_fnc_factionVehicule;

if (isNull _groupe || { _vehic isEqualTo "" }) exitWith {
    diag_log format ["[HDS][TACTIQUES] Aucun appui possible pour %1", _id];
};

diag_log format [
    "[HDS][TACTIQUES] %1 n'a pas d'helicoptere — appui terrestre : %2 dans %3",
    _id, configName _groupe, _vehic
];

[_position, _groupe, _distanceproche, _side, _vehic, 1] spawn fnc_tactique_renfortvehiculer;
