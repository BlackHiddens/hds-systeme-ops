/*
 * hds_fnc_factionsScanVehicules
 * ─────────────────────────────────────────────────────────────
 * Parcourt CfgVehicles et range les véhicules par faction et par rôle.
 *
 * Le tri des véhicules ne peut pas venir de CfgGroups : beaucoup de
 * factions déclarent des véhicules sans groupe associé. On lit donc
 * CfgVehicles, filtré sur "scope >= 2" et "faction non vide" pour
 * écarter les classes de base et les objets non jouables.
 *
 * Le type est déduit de "simulation", qui est fiable et bon marché
 * à lire — bien plus que isKindOf sur chaque classe.
 *
 * Aucun paramètre. Retourne true.
 */

private _simsRoulant = ["carx", "motorcycle"];
private _simsHelico  = ["helicopterx", "helicopterrtd"];
private _simsRetenus = _simsRoulant + _simsHelico + ["tankx", "airplanex", "shipx"];

private _sidesParNum = [east, west, independent, civilian];
private _nomsParNum  = ["EAST", "WEST", "INDEP", "CIV"];

// Le filtre sur la simulation est DANS la condition : elle est évaluée
// par le moteur, bien plus vite qu'une itération SQF. Le premier jet
// ramenait 35479 candidats pour n'en garder que 17912 — la moitié du
// travail était faite en SQF pour rien.
private _candidats = "
    getNumber (_x >> 'scope') >= 2
    && { getText (_x >> 'faction') != '' }
    && { (toLower (getText (_x >> 'simulation'))) in
         ['carx','motorcycle','helicopterx','helicopterrtd','tankx','airplanex','shipx'] }
" configClasses (configFile >> "CfgVehicles");

private _n = 0;

{
    private _cfg = _x;
    private _sim = toLower (getText (_cfg >> "simulation"));

    if (_sim in _simsRetenus) then {
        private _cls       = configName _cfg;
        private _idFaction = getText (_cfg >> "faction");
        private _places    = getNumber (_cfg >> "transportSoldier");
        // isClass sur MainTurret plutôt qu'énumérer Turrets : une lecture
        // au lieu d'un parcours, sur 17912 véhicules ça compte.
        private _tourelles = isClass (_cfg >> "Turrets" >> "MainTurret");

        private _role = switch (true) do {
            case (_sim in _simsHelico): {
                ["HELICO_ARME", "HELICO_TRANSPORT"] select (_places >= 4)
            };
            case (_sim == "airplanex"): { "AVION" };
            case (_sim == "shipx"):     { "NAVAL" };
            case (_sim == "tankx"):     { ["BLINDE", "MECANISE"] select (_places >= 4) };
            default {
                if (_places >= 6) then { "CAMION" }
                else { ["LEGER", "ARME"] select _tourelles }
            };
        };

        // ─── Entrée faction : créée si le scan CfgGroups ne l'a pas vue ───
        private _f = hds_factions get _idFaction;
        if (isNil "_f") then {
            private _num = getNumber (_cfg >> "side");
            if (_num < 0 || _num > 3) then { _num = 0 };
            private _sideNom = _nomsParNum select _num;

            private _nom = getText (configFile >> "CfgFactionClasses" >> _idFaction >> "displayName");
            if (_nom isEqualTo "") then { _nom = _idFaction };

            _f = createHashMapFromArray [
                ["id",      _idFaction],
                ["nom",     _nom],
                ["side",    _sidesParNum select _num],
                ["sideNom", _sideNom],
                ["groupes", createHashMap],
                ["veh",     createHashMap]
            ];
            hds_factions set [_idFaction, _f];

            private _liste = hds_factions_par_side getOrDefault [_sideNom, []];
            _liste pushBackUnique _idFaction;
            hds_factions_par_side set [_sideNom, _liste];
        };

        private _parRole = _f get "veh";
        private _l = _parRole getOrDefault [_role, []];
        // pushBack et non pushBackUnique : configClasses ne rend jamais
        // deux fois la même classe, et pushBackUnique coûte un parcours
        // du tableau à chaque insertion — quadratique sur 17912 entrées.
        _l pushBack _cls;
        _parRole set [_role, _l];

        _n = _n + 1;
    };

} forEach _candidats;

["INFO", "FACTIONS", format [
    "CfgVehicles : %1 vehicules ranges sur %2 candidats",
    _n, count _candidats
]] call hds_fnc_log;

true
