/*
 * hds_fnc_factionsScanCivils
 * ─────────────────────────────────────────────────────────────
 * Range les civils par faction, dans le bac "hommes" de chaque entrée.
 *
 * ── Pourquoi une passe à part ──
 * Les civils échappent aux deux autres scans. Ils ne sont presque
 * jamais dans CfgGroups — personne ne déclare de composition de groupe
 * pour des passants — et le scan des véhicules écarte explicitement
 * simulation = "soldier".
 *
 * La condition est volontairement étroite : side == 3, soit le camp
 * civil. C'est une petite partie de CfgVehicles, donc la passe reste
 * bon marché là où retenir TOUS les hommes de toutes les factions
 * doublerait le coût du scan pour un besoin qu'on n'a pas.
 *
 * Le jour où il faudra des hommes d'un autre camp, c'est la condition
 * side qu'on élargit, et rien d'autre.
 *
 * Aucun paramètre. Retourne true.
 */

private _sidesParNum = [east, west, independent, civilian];
private _nomsParNum  = ["EAST", "WEST", "INDEP", "CIV"];

private _candidats = "
    getNumber (_x >> 'scope') >= 2
    && { getNumber (_x >> 'side') == 3 }
    && { (toLower (getText (_x >> 'simulation'))) == 'soldier' }
" configClasses (configFile >> "CfgVehicles");

private _n = 0;

{
    private _cfg = _x;
    private _cls = configName _cfg;
    private _idFaction = getText (_cfg >> "faction");

    if (_idFaction != "") then {

        // ─── Entrée faction, créée si les autres scans ne l'ont pas vue ───
        private _f = hds_factions get _idFaction;
        if (isNil "_f") then {
            private _nom = getText (configFile >> "CfgFactionClasses" >> _idFaction >> "displayName");
            if (_nom isEqualTo "") then { _nom = _idFaction };

            _f = createHashMapFromArray [
                ["id",      _idFaction],
                ["nom",     _nom],
                ["side",    _sidesParNum select 3],
                ["sideNom", _nomsParNum select 3],
                ["groupes", createHashMap],
                ["veh",     createHashMap]
            ];
            hds_factions set [_idFaction, _f];

            private _liste = hds_factions_par_side getOrDefault ["CIV", []];
            _liste pushBackUnique _idFaction;
            hds_factions_par_side set ["CIV", _liste];
        };

        private _hommes = _f getOrDefault ["hommes", []];
        _hommes pushBack _cls;
        _f set ["hommes", _hommes];

        _n = _n + 1;
    };

} forEach _candidats;

["INFO", "FACTIONS", format [
    "Civils : %1 classes rangees sur %2 candidats", _n, count _candidats
]] call hds_fnc_log;

true
