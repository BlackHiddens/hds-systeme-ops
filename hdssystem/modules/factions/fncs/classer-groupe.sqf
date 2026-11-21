/*
 * hds_fnc_factionsClasserGroupe
 * ─────────────────────────────────────────────────────────────
 * Détermine le rôle de composition d'une entrée CfgGroups, et
 * vérifie au passage qu'elle est réellement spawnable.
 *
 * 0 : <CONFIG> l'entrée groupe de CfgGroups
 * 1 : <STRING> nom de la classe de catégorie parente (indice de rôle)
 *
 * Retourne : [_role, _nbHommes, _manquantes]
 *   _role        <STRING> un de hds_factions_roles, "" si inexploitable
 *   _nbHommes    <NUMBER>
 *   _manquantes  <ARRAY>  classes déclarées mais absentes de CfgVehicles
 *
 * Un groupe est écarté si une seule de ses unités manque : le spawn
 * produirait un groupe incomplet, donc inutilisable pour une garnison
 * ou un assaut. C'est ce qui permet de supporter les mods de compat
 * à moitié installés sans échec silencieux en jeu.
 *
 * ── Pourquoi un cache ──
 * Première mesure réelle avec RHS : 4426 ms pour 11585 groupes. Le coût
 * était ici, pas dans le parcours de CfgGroups : chaque groupe
 * interrogeait la config pour chacune de ses unités (isClass, scope,
 * isKindOf), soit de l'ordre de 90 000 lectures pour quelques milliers
 * de classes distinctes. Le verdict est donc mémorisé par classe dans
 * hds_factions_cache_genre, et une classe n'est examinée qu'une fois.
 */

params ["_cfgGroupe", ["_categorie", ""]];

// ─── Classes d'unités déclarées par le groupe ───
private _unites = [];
{
    private _cls = getText (_x >> "vehicle");
    if (_cls != "") then { _unites pushBack _cls };
} forEach ("true" configClasses _cfgGroupe);

if (_unites isEqualTo []) exitWith { ["", 0, []] };

// ─── Genre de chaque unité, via le cache ───
private _genres = [];
private _manquantes = [];

{
    private _cls = _x;
    private _e = hds_factions_cache_genre get _cls;

    if (isNil "_e") then {
        private _cfg = configFile >> "CfgVehicles" >> _cls;
        private _genre  = "ABSENT";
        private _places = 0;
        private _tour   = false;

        if (isClass _cfg && { (getNumber (_cfg >> "scope")) >= 2 }) then {
            _places = getNumber (_cfg >> "transportSoldier");
            // isClass sur MainTurret plutôt qu'énumérer Turrets : une
            // lecture au lieu d'un parcours, pour la même information utile.
            _tour   = isClass (_cfg >> "Turrets" >> "MainTurret");
            _genre  = switch (true) do {
                case (_cls isKindOf "Man"):          { "MAN" };
                case (_cls isKindOf "Air"):          { "AIR" };
                case (_cls isKindOf "Ship"):         { "SHIP" };
                case (_cls isKindOf "Tank"):         { "TANK" };
                case (_cls isKindOf "StaticWeapon"): { "STATIC" };
                default                              { "ROULANT" };
            };
        };

        _e = [_genre, _places, _tour];
        hds_factions_cache_genre set [_cls, _e];
    };

    if ((_e select 0) isEqualTo "ABSENT") then { _manquantes pushBack _cls };
    _genres pushBack _e;

} forEach _unites;

if (count _manquantes > 0) exitWith { ["", 0, _manquantes] };

private _g  = _genres apply { _x select 0 };
private _nH = count (_g select { _x isEqualTo "MAN" });

// ═══ Le rôle vient du matériel le plus lourd du groupe ═══

if ("AIR"  in _g) exitWith { ["AIR", _nH, []] };

if ("SHIP" in _g) exitWith { ["NAVAL", _nH, []] };

if ("TANK" in _g) exitWith {
    // Un blindé qui embarque de l'infanterie = mécanisé, sinon blindé pur
    private _transporte = (_genres findIf {
        (_x select 0) isEqualTo "TANK" && { (_x select 1) >= 4 }
    }) != -1;
    [(["BLINDE", "MECANISE"] select _transporte), _nH, []]
};

if ("STATIC" in _g) exitWith { ["SUPPORT", _nH, []] };

if ("ROULANT" in _g) exitWith {
    // Roulant armé et capable d'embarquer un groupe = mécanisé
    private _vci = (_genres findIf {
        (_x select 0) isEqualTo "ROULANT" && { (_x select 1) >= 6 } && { _x select 2 }
    }) != -1;
    [(["MOTORISE", "MECANISE"] select _vci), _nH, []]
};

// ═══ Infanterie pure ═══

if (_nH == 0) exitWith { ["", 0, []] };

// Indice donné par le nom de la catégorie parente.
// On reste sur des fragments génériques : ils se retrouvent aussi bien
// dans les catégories vanilla que chez RHS, CUP, LOP, 3CB...
private _cat = toLower _categorie;
private _indices = [
    [["recon", "spec", "diver", "scout", "sniper_team"], "RECON"],
    [["sniper", "sharpshooter", "tireur"],               "SNIPER"],
    [["support", "mortar", "weapon", "appui", "mg_"],    "SUPPORT"]
];

private _roleCat = "";
{
    _x params ["_mots", "_role"];
    if ((_mots findIf { (_cat find _x) != -1 }) != -1) exitWith { _roleCat = _role };
} forEach _indices;

if (_roleCat != "") exitWith { [_roleCat, _nH, []] };

// Sinon : la taille décide
private _role = switch (true) do {
    case (_nH <= 4): { "FIRETEAM" };
    case (_nH <= 9): { "SQUAD" };
    default          { "SECTION" };
};

[_role, _nH, []]
