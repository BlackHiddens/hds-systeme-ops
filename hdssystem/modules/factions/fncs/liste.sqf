/*
 * hds_fnc_factionsListe
 * ─────────────────────────────────────────────────────────────
 * Rend le registre sous une forme compacte et sérialisable.
 *
 * Destiné à être consommé par autre chose que du SQF : une interface
 * externe ne peut pas lire une hashmap du serveur, mais elle peut
 * lire une ligne de RPT. Cette fonction produit la donnée, dump.sqf
 * l'écrit dans le RPT.
 *
 * 0 : <STRING> filtre de camp : "" (tous), "EAST", "WEST", "INDEP", "CIV"
 *
 * Retourne : <ARRAY> une entrée par faction, rôles les mieux fournis
 *            en premier
 *   [_id, _nom, _sideNom, [[role, nb], ...], [[roleVeh, nb], ...]]
 *
 * Exemple de sortie :
 *   ["OPF_F", "CSAT", "EAST", [["SQUAD",6],["FIRETEAM",4]], [["CAMION",3]]]
 */

params [["_filtreCamp", ""]];

private _filtre = toUpper _filtreCamp;
private _sortie = [];

// Range une hashmap "role → tableau" en [[role, nb], ...] décroissant
private _parEffectif = {
    params ["_hm"];
    private _tmp = [];
    { _tmp pushBack [count _y, _x]; } forEach _hm;
    _tmp sort false;
    _tmp apply { [_x select 1, _x select 0] }
};

{
    private _f = _y;
    private _sideNom = _f get "sideNom";

    if (_filtre isEqualTo "" || { _filtre isEqualTo _sideNom }) then {
        _sortie pushBack [
            _f get "id",
            _f get "nom",
            _sideNom,
            [_f get "groupes"] call _parEffectif,
            [_f get "veh"]     call _parEffectif
        ];
    };
} forEach hds_factions;

// Factions les plus fournies en premier.
// On trie des paires [score, index] et non [score, entree] : sort ne
// sait pas comparer deux tableaux imbriques en cas d'egalite.
private _rangs = [];
for "_i" from 0 to ((count _sortie) - 1) do {
    private _e = _sortie select _i;
    _rangs pushBack [(count (_e select 3)) + (count (_e select 4)), _i];
};
_rangs sort false;

_rangs apply { _sortie select (_x select 1) }
