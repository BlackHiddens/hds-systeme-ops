/*
 * hds_fnc_factionGroupe
 * ─────────────────────────────────────────────────────────────
 * Rend UNE entrée CfgGroups qui répond à une intention.
 * Tirage au sort dans ce que rend hds_fnc_factionGroupes.
 *
 * 0 : <NUMBER|STRING|SIDE> faction (voir hds_fnc_factionResoudre)
 * 1 : <STRING> intention : GARNISON, PATROUILLE, RECON, ASSAUT,
 *              SUPPORT, MOTORISE, MECANISE, BLINDE, AIR, NAVAL
 *
 * Retourne : <CONFIG> entrée groupe, configNull si rien
 *
 * Exemple :
 *   private _cfg = [east, "GARNISON"] call hds_fnc_factionGroupe;
 *   if (!isNull _cfg) then {
 *       private _grp = [_pos, east, _cfg] call BIS_fnc_spawnGroup;
 *   };
 */

params [["_faction", east], ["_intention", "GARNISON"]];

private _l = [_faction, _intention] call hds_fnc_factionGroupes;

if (_l isEqualTo []) exitWith { configNull };

selectRandom _l
