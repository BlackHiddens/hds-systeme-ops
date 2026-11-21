/*
 * hds_fnc_factionResoudre
 * ─────────────────────────────────────────────────────────────
 * Traduit n'importe quelle façon de désigner une faction en un
 * couple [id de faction, camp] réellement disponible sur ce serveur.
 *
 * 0 : <NUMBER|STRING|SIDE> la demande
 *     NUMBER  → ancien index 0..7 du système HDS (compatibilité :
 *               c'est ce que produisent le générateur web et tout
 *               le code existant)
 *     STRING  → id de faction ("OPF_F", "rhs_faction_msv"),
 *               ou "AUTO" pour déduire du terrain
 *     SIDE    → déduit la faction de ce que la mission a posé
 *
 * Retourne : [_id, _side]
 *   _id   <STRING> id de faction garanti présent dans le registre,
 *                  "" seulement si le camp n'existe pas du tout
 *   _side <SIDE>
 *
 * Si la faction demandée n'est pas sur le serveur (index 5 = RHS sans
 * RHS installé), on retombe sur une faction du même camp, vanilla en
 * premier. Un appel ne peut donc pas échouer faute de mod.
 */

params [["_demande", east]];

private _id   = "";
private _side = east;

switch (true) do {

    // ─── Ancien index numérique ───
    case (_demande isEqualType 0): {
        private _e = hds_factions_legacy getOrDefault [_demande, []];
        if !(_e isEqualTo []) then {
            _id   = _e select 0;
            _side = _e select 1;
        };
    };

    // ─── Id de faction, ou "AUTO" ───
    case (_demande isEqualType ""): {
        if ((toUpper _demande) in ["AUTO", ""]) then {
            _id = [_side] call hds_fnc_factionDuTerrain;
        } else {
            _id = _demande;
            private _f = hds_factions get _id;
            if (!isNil "_f") then { _side = _f get "side" };
        };
    };

    // ─── Camp : on regarde ce que la mission a posé ───
    case (_demande isEqualType east): {
        _side = _demande;
        _id   = [_side] call hds_fnc_factionDuTerrain;
    };
};

// ─── Garantie de disponibilité ───
if (_id isEqualTo "" || { isNil { hds_factions get _id } }) then {
    private _sideNom = [_side] call hds_fnc_factionsSideNom;
    private _dispo   = hds_factions_par_side getOrDefault [_sideNom, []];
    private _van     = _dispo select { _x in hds_factions_vanilla };

    private _repli = if (count _van > 0) then { _van select 0 } else {
        if (count _dispo > 0) then { _dispo select 0 } else { "" }
    };

    if (hdssysteme) then {
        diag_log format [
            "[HDS][FACTIONS] Demande %1 indisponible - repli sur %2 (%3)",
            _demande, (["aucune", _repli] select (_repli != "")), _sideNom
        ];
    };

    _id = _repli;
};

[_id, _side]
