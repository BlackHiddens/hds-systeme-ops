/*
 * hds_fnc_factionHommes
 * ─────────────────────────────────────────────────────────────
 * Rend les classes d'hommes d'une faction — en pratique ses civils,
 * seuls rangés par hds_fnc_factionsScanCivils.
 *
 * 0 : <STRING|SIDE> id de faction, ou un camp (on prend alors la
 *                   première faction de ce camp qui en a)
 *
 * Retourne : <ARRAY> classnames, [] si rien
 *
 * Repli : la faction demandée, puis les autres factions du même camp,
 * les vanilla d'abord. Une population civile demandée pour un mod
 * absent se peuple donc en civils vanilla au lieu de ne rien produire.
 */

params [["_faction", civilian]];

if (!hds_factions_pret) then {
    diag_log "[HDS][FACTIONS] /!\ Registre pas encore pret - attendre hds_factions_pret";
};

// ─── Camp visé et faction demandée ───
private _sideNom = "CIV";
private _id = "";

if (_faction isEqualType "") then {
    _id = _faction;
    private _f = hds_factions get _id;
    if (!isNil "_f") then { _sideNom = _f get "sideNom" };
} else {
    _sideNom = [_faction] call hds_fnc_factionsSideNom;
};

private _trouve = [];

// ─── 1) La faction demandée ───
if (_id != "") then {
    private _f = hds_factions get _id;
    if (!isNil "_f") then {
        _trouve = +(_f getOrDefault ["hommes", []]);
    };
};

if !(_trouve isEqualTo []) exitWith { _trouve };

// ─── 2) Les autres factions du camp, vanilla d'abord ───
private _dispo = (hds_factions_par_side getOrDefault [_sideNom, []]) - [_id];
_dispo = (_dispo select { _x in hds_factions_vanilla })
       + (_dispo select { !(_x in hds_factions_vanilla) });

private _idRepli = "";

{
    private _f = hds_factions get _x;
    if (!isNil "_f") then {
        private _h = _f getOrDefault ["hommes", []];
        if (count _h > 0) then { _trouve = +_h; _idRepli = _x };
    };
    if !(_trouve isEqualTo []) exitWith {};
} forEach _dispo;

if (_trouve isEqualTo []) then {
    diag_log format ["[HDS][FACTIONS] Aucun homme disponible pour %1 (camp %2)", _faction, _sideNom];
} else {
    if (hdssysteme) then {
        diag_log format ["[HDS][FACTIONS] Hommes : %1 servi par %2 (%3 classes)",
            _faction, _idRepli, count _trouve];
    };
};

_trouve
