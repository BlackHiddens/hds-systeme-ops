/*
 * hds_fnc_factionsExportDemande
 * ─────────────────────────────────────────────────────────────
 * Un client veut le registre : le serveur le construit et le lui
 * renvoie.
 *
 * 0 : <OBJECT> le joueur demandeur
 * 1 : <STRING> filtre de camp ("" = tous)
 *
 * CÔTÉ SERVEUR. Le registre n'existe que là, donc un client ne peut pas
 * fabriquer le JSON lui-même — il doit le demander.
 *
 * Appelé depuis le client par :
 *   [player, ""] remoteExec ["hds_fnc_factionsExportDemande", 2];
 */

if (!isServer) exitWith { false };

params [["_demandeur", objNull], ["_filtre", ""]];

if (isNull _demandeur) exitWith {
    ["ALERTE", "FACTIONS", "Export demande sans demandeur identifiable"] call hds_fnc_log;
    false
};

private _json = [_filtre] call hds_fnc_factionsExport;

[_json] remoteExec ["hds_fnc_factionsExportRecoit", _demandeur];

true
