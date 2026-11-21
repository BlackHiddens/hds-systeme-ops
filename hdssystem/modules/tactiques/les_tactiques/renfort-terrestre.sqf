/*
 * fnc_tactique_renfortterrestre
 * ─────────────────────────────────────────────────────────────
 * Fait arriver un véhicule de transport chargé de soldats sur une
 * position, par la route.
 *
 * 0 : <ARRAY|STRING>        position, ou nom de marqueur
 * 1 : <NUMBER>              distance d'approche (m)
 * 2 : <NUMBER|STRING|SIDE>  faction
 *
 * Le groupe et le véhicule viennent du registre de factions : plus de
 * classname en dur, et une faction absente du serveur retombe sur une
 * faction du même camp au lieu de ne rien produire.
 *
 * À lancer avec spawn :
 *   [_pos, 800, east] spawn fnc_tactique_renfortterrestre;
 */

params [["_position", [0,0,0]], ["_distanceproche", 800], ["_camps", east]];

if (hdssysteme) then {
    [format ["%1 : Renfort d'infanterie véhiculé par voie terrestre", hdstactiqueversion]]
        remoteExecCall ["systemChat", 0];
};

// ─── Registre rempli de façon asynchrone au démarrage ───
if (!hds_factions_pret) then {
    if (canSuspend) then { waitUntil { hds_factions_pret } };
};

([_camps] call hds_fnc_factionResoudre) params ["_id", "_side"];

private _groupe = [_id, "PATROUILLE"] call hds_fnc_factionGroupe;
private _vehic  = [_id, "TRANSPORT"]  call hds_fnc_factionVehicule;

if (isNull _groupe || { _vehic isEqualTo "" }) exitWith {
    diag_log format [
        "[HDS][TACTIQUES] Renfort terrestre impossible pour %1 (groupe:%2 vehicule:%3)",
        _id, !isNull _groupe, _vehic != ""
    ];
};

if (hdssysteme) then {
    diag_log format [
        "[HDS][TACTIQUES] Renfort terrestre %1 [%2] — %3 dans %4",
        _id, _side, configName _groupe, _vehic
    ];
};

[_position, _groupe, _distanceproche, _side, _vehic, 2] spawn fnc_tactique_renfortvehiculer;
