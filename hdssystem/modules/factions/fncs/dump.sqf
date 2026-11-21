/*
 * hds_fnc_factionsDump
 * ─────────────────────────────────────────────────────────────
 * Écrit le registre dans le RPT, sous deux formes :
 *
 *   [HDS][FACTIONS_DUMP]   lisible à l'œil, une ligne par faction
 *                          (uniquement si hdssysteme = true)
 *
 *   [HDS][FACTIONS_LISTE]  une seule ligne, tableau brut, destinée à
 *                          être lue par une interface externe qui
 *                          suit le RPT. C'est le seul moyen pour un
 *                          outil hors Arma de savoir quelles factions
 *                          existent réellement sur CE serveur.
 *
 * Aucun paramètre. Retourne true.
 */

private _liste = [""] call hds_fnc_factionsListe;

// ─── Ligne machine : toujours écrite ───
diag_log format ["[HDS][FACTIONS_LISTE]%1", _liste];

// ─── Trace lisible : seulement en debug ───
if (hdssysteme) then {

    diag_log "[HDS][FACTIONS_DUMP] ----------- REGISTRE DES FACTIONS -----------";

    // Avec RHS chargé, le scan trouve plus de 200 factions : en détailler
    // chacune noierait le RPT sous 600 lignes. On montre les mieux
    // fournies, la ligne FACTIONS_LISTE garde le tout.
    private _plafond = 25;
    private _montrees = _liste select [0, _plafond];

    {
        _x params ["_id", "_nom", "_sideNom", "_groupes", "_veh"];

        private _nbG = 0;
        { _nbG = _nbG + (_x select 1); } forEach _groupes;
        private _nbV = 0;
        { _nbV = _nbV + (_x select 1); } forEach _veh;

        diag_log format [
            "[HDS][FACTIONS_DUMP] %1 [%2] %3 - %4 groupes / %5 vehicules",
            _nom, _sideNom, _id, _nbG, _nbV
        ];

        if (count _groupes > 0) then {
            diag_log format ["[HDS][FACTIONS_DUMP]     groupes : %1", _groupes];
        };
        if (count _veh > 0) then {
            diag_log format ["[HDS][FACTIONS_DUMP]     vehicules : %1", _veh];
        };

    } forEach _montrees;

    if (count _liste > _plafond) then {
        diag_log format [
            "[HDS][FACTIONS_DUMP] ... et %1 autres factions, voir [HDS][FACTIONS_LISTE]",
            (count _liste) - _plafond
        ];
    };

    // ─── Factions déduites du terrain, camp par camp ───
    {
        private _f = [_x] call hds_fnc_factionDuTerrain;
        diag_log format [
            "[HDS][FACTIONS_DUMP] Camp %1 -> faction retenue : %2",
            [_x] call hds_fnc_factionsSideNom,
            (["aucune", _f] select (_f != ""))
        ];
    } forEach [east, west, independent];

    diag_log "[HDS][FACTIONS_DUMP] ----------------------------------------------";
};

true
