/*
 * hds_fnc_factionsScanGroupes
 * ─────────────────────────────────────────────────────────────
 * Parcourt CfgGroups et remplit hds_factions / hds_factions_par_side.
 *
 * Structure parcourue :
 *   CfgGroups > <Camp> > <Faction> > <Categorie> > <Groupe> > Unit0..N
 *
 * Les quatre conteneurs de camp sont énumérés et non nommés en dur :
 * c'est ce qui évite le piège classique du chemin écrit à la main
 * ("independent" au lieu de "Indep" renvoie une config nulle et
 * BIS_fnc_spawnGroup échoue sans rien dire).
 *
 * Aucun paramètre. Retourne true.
 */

private _sidesParNum = [east, west, independent, civilian];
private _nomsParNum  = ["EAST", "WEST", "INDEP", "CIV"];

private _nbGroupes = 0;
private _nbEcartes = 0;
private _manquantes = [];

{
    private _cfgCamp = _x;
    private _nomCamp = toLower (configName _cfgCamp);

    // Camp déduit du conteneur, ce que BIS fixe une fois pour toutes
    private _numCamp = switch (true) do {
        case (_nomCamp == "east"): { 0 };
        case (_nomCamp == "west"): { 1 };
        case (_nomCamp in ["indep", "guerrila", "guerrilla", "resistance"]): { 2 };
        case (_nomCamp in ["civ", "civilian"]): { 3 };
        default { -1 };
    };

    {
        private _cfgFaction = _x;
        private _idFaction  = configName _cfgFaction;

        {
            private _cfgCat = _x;
            private _nomCat = configName _cfgCat;

            {
                private _cfgGroupe = _x;

                ([_cfgGroupe, _nomCat] call hds_fnc_factionsClasserGroupe)
                    params ["_role", "_nbH", "_manque"];

                if (_role isEqualTo "") then {
                    _nbEcartes = _nbEcartes + 1;
                    // Plafonné : cette liste ne sert qu'à une trace qui en
                    // affiche 8. Sans plafond, pushBackUnique reparcourt un
                    // tableau de plusieurs centaines d'entrées 407 fois.
                    if (count _manquantes < 50) then {
                        { _manquantes pushBackUnique _x } forEach _manque;
                    };
                } else {
                    // Camp : conteneur d'abord, attribut du groupe en secours
                    private _num = _numCamp;
                    if (_num < 0) then { _num = getNumber (_cfgGroupe >> "side") };
                    if (_num < 0 || _num > 3) then { _num = 0 };

                    private _sideNom = _nomsParNum select _num;

                    // ─── Création paresseuse de l'entrée faction ───
                    private _f = hds_factions get _idFaction;
                    if (isNil "_f") then {
                        private _nom = getText (configFile >> "CfgFactionClasses" >> _idFaction >> "displayName");
                        if (_nom isEqualTo "") then {
                            _nom = getText (_cfgFaction >> "name");
                        };
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

                    // ─── Rangement par rôle ───
                    private _parRole = _f get "groupes";
                    private _l = _parRole getOrDefault [_role, []];
                    _l pushBack _cfgGroupe;
                    _parRole set [_role, _l];

                    _nbGroupes = _nbGroupes + 1;
                };

            } forEach ("true" configClasses _cfgCat);

        } forEach ("true" configClasses _cfgFaction);

    } forEach ("true" configClasses _cfgCamp);

} forEach ("true" configClasses (configFile >> "CfgGroups"));

["INFO", "FACTIONS", format [
    "CfgGroups : %1 groupes retenus, %2 ecartes, %3 factions",
    _nbGroupes, _nbEcartes, count hds_factions
]] call hds_fnc_log;

if (hdssysteme && { count _manquantes > 0 }) then {
    diag_log format [
        "[HDS][FACTIONS] %1 classes referencees mais absentes (mod de compat manquant ?) ex: %2",
        count _manquantes,
        _manquantes select [0, 8]
    ];
};

true
