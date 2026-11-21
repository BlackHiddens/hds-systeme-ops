/*
 * hds_fnc_factionsExportRecoit
 * ─────────────────────────────────────────────────────────────
 * Le serveur a renvoyé le registre : on le pose dans le presse-papier.
 *
 * 0 : <STRING> le JSON
 *
 * CÔTÉ CLIENT. Compilée depuis mes-parametres.sqf, qui est inclus des
 * deux côtés : si elle ne l'était que par le module factions, elle
 * n'existerait que sur le serveur et le remoteExec tomberait dans le
 * vide.
 *
 * Après ça : coller dans le générateur de mission, bouton « Importer le
 * registre du serveur ».
 */

if (!hasInterface) exitWith { false };

params [["_json", ""]];

if (_json isEqualTo "") exitWith {
    hint "Registre vide — le scan est peut-etre encore en cours.";
    false
};

copyToClipboard _json;

// Compte approximatif, juste pour confirmer que ce n'est pas vide
private _nb = (count (_json splitString "{")) - 1;

hint parseText format [
    "<t size='1.1' color='#00aaff'><b>Registre copié</b></t><br/>"
  + "<t size='0.9'>%1 factions, %2 caractères dans le presse-papier.<br/>"
  + "À coller dans le générateur de mission.</t>",
    (_nb - 1) max 0, count _json
];

diag_log format ["[HDS][FACTIONS] Registre copie dans le presse-papier (%1 caracteres)", count _json];

true
