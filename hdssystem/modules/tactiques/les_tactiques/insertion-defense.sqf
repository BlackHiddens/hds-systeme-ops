/*
 * fnc_tactique_insertion
 * ─────────────────────────────────────────────────────────────
 * Fait arriver un groupe d'infanterie sur une position, par les airs
 * si la faction dispose d'un hélicoptère, par la route sinon.
 *
 * 0 : <ARRAY|STRING>        position, ou nom de marqueur
 * 1 : <NUMBER>              distance d'approche (m)
 * 2 : <NUMBER|STRING|SIDE>  faction
 *
 * L'ancienne version promettait « par voie aérienne si possible »
 * mais le choix était figé par faction : trois d'entre elles
 * arrivaient en camion quoi qu'il arrive, et une quatrième empruntait
 * un hélico d'un autre camp. Ici le repli est explicite et tracé.
 *
 * À lancer avec spawn :
 *   [_pos, 800, east] spawn fnc_tactique_insertion;
 */

params [["_position", [0,0,0]], ["_distanceapproche", 800], ["_camps", east]];

if (hdssysteme) then {
    [format ["%1 : Déploiement de renfort d'infanterie, par voie aérienne si possible", hdstactiqueversion]]
        remoteExecCall ["systemChat", 0];
};

if (!hds_factions_pret) then {
    if (canSuspend) then { waitUntil { hds_factions_pret } };
};

([_camps] call hds_fnc_factionResoudre) params ["_id", "_side"];

private _groupe = [_id, "PATROUILLE"] call hds_fnc_factionGroupe;

if (isNull _groupe) exitWith {
    diag_log format ["[HDS][TACTIQUES] Insertion impossible pour %1 : aucun groupe", _id];
};

// ─── Hélicoptère de transport d'abord, route en repli ───
private _vehic = [_id, "HELICO"] call hds_fnc_factionVehicule;
private _voie  = "aerienne";

if (_vehic isEqualTo "") then {
    _vehic = [_id, "TRANSPORT"] call hds_fnc_factionVehicule;
    _voie  = "terrestre";
};

if (_vehic isEqualTo "") exitWith {
    diag_log format ["[HDS][TACTIQUES] Insertion impossible pour %1 : aucun vehicule", _id];
};

if (hdssysteme) then {
    diag_log format [
        "[HDS][TACTIQUES] Insertion %1 [%2] par voie %3 — %4 dans %5",
        _id, _side, _voie, configName _groupe, _vehic
    ];
};

[_position, _groupe, _distanceapproche, _side, _vehic, 2] spawn fnc_tactique_renfortvehiculer;
