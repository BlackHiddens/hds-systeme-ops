/*
 * hds_fnc_factionVehicule
 * ─────────────────────────────────────────────────────────────
 * Rend UN classname de véhicule qui répond à une intention.
 * Tirage au sort dans ce que rend hds_fnc_factionVehicules.
 *
 * 0 : <NUMBER|STRING|SIDE> faction (voir hds_fnc_factionResoudre)
 * 1 : <STRING> intention : TRANSPORT, PATROUILLE, LEGER, BLINDE,
 *              HELICO, HELICO_ARME, AVION, NAVAL
 *
 * Retourne : <STRING> classname, "" si rien
 *
 * Exemple :
 *   private _cls = [east, "CAMION"] call hds_fnc_factionVehicule;
 *   if (_cls != "") then {
 *       private _v = [_pos, 180, _cls, east] call BIS_fnc_spawnVehicle;
 *   };
 */

params [["_faction", east], ["_intention", "TRANSPORT"]];

private _l = [_faction, _intention] call hds_fnc_factionVehicules;

if (_l isEqualTo []) exitWith { "" };

selectRandom _l
