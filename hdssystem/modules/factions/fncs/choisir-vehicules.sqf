/*
 * hds_fnc_factionVehicules
 * ─────────────────────────────────────────────────────────────
 * Rend TOUS les véhicules d'une faction qui répondent à une
 * intention, avec la même chaîne de repli que les groupes.
 *
 * 0 : <NUMBER|STRING|SIDE> faction (voir hds_fnc_factionResoudre)
 * 1 : <STRING> intention : TRANSPORT, PATROUILLE, LEGER, BLINDE,
 *              HELICO, HELICO_ARME, AVION, NAVAL
 *              (ou directement un nom de rôle véhicule)
 *
 * Retourne : <ARRAY> classnames, [] si rien
 *
 * C'est la forme qu'attendent les occupations : elles ont besoin de
 * la liste complète pour varier les véhicules d'une patrouille à
 * l'autre, pas d'un tirage unique.
 */

params [["_faction", east], ["_intention", "TRANSPORT"]];

if (!hds_factions_pret) then {
    diag_log "[HDS][FACTIONS] /!\ Registre pas encore pret - attendre hds_factions_pret";
};

([_faction] call hds_fnc_factionResoudre) params ["_id", "_side"];

if (_id isEqualTo "") exitWith { [] };

private _f = hds_factions get _id;
if (isNil "_f") exitWith { [] };

// Une intention véhicule, ou directement un nom de rôle
private _intMaj = toUpper _intention;
private _roles  = hds_factions_intentions_veh getOrDefault [_intMaj, []];
if (_roles isEqualTo []) then {
    if (_intMaj in hds_factions_roles_veh) then {
        _roles = [_intMaj];
    } else {
        diag_log format ["[HDS][FACTIONS] Intention vehicule inconnue : %1 - repli TRANSPORT", _intention];
        _roles = hds_factions_intentions_veh get "TRANSPORT";
    };
};

private _trouve = [];

// ─── 1) Dans la faction résolue ───
private _parRole = _f get "veh";
{
    private _l = _parRole getOrDefault [_x, []];
    if (count _l > 0) exitWith { _trouve = +_l };
} forEach _roles;

if !(_trouve isEqualTo []) exitWith { _trouve };

// ─── 2) Autres factions du même camp, vanilla d'abord ───
private _sideNom = _f get "sideNom";
private _autres  = (hds_factions_par_side getOrDefault [_sideNom, []]) - [_id];
_autres = (_autres select { _x in hds_factions_vanilla })
        + (_autres select { !(_x in hds_factions_vanilla) });

private _idRepli = "";
{
    private _idAutre = _x;
    private _g = hds_factions get _idAutre;
    if (!isNil "_g") then {
        private _pr = _g get "veh";
        {
            private _l = _pr getOrDefault [_x, []];
            if (count _l > 0) exitWith { _trouve = +_l };
        } forEach _roles;
    };
    if !(_trouve isEqualTo []) exitWith { _idRepli = _idAutre };
} forEach _autres;

if (_trouve isEqualTo []) then {
    diag_log format ["[HDS][FACTIONS] Aucun vehicule pour %1 / %2", _id, _intention];
} else {
    if (hdssysteme && { _idRepli != "" }) then {
        diag_log format [
            "[HDS][FACTIONS] Repli vehicule : %1 / %2 servi par %3 (%4 classes)",
            _id, _intention, _idRepli, count _trouve
        ];
    };
};

_trouve
