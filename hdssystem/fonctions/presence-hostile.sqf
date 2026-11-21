/*
 * fnc_hds_presence_hostile
 * ─────────────────────────────────────────────────────────────
 * Sème une présence ennemie sur toute la carte : une occupation et de
 * la planification tactique sur chaque localisation retenue. Sert à
 * peupler l'arrière-plan d'un scénario, pour que la carte ne soit pas
 * vide entre deux objectifs.
 *
 * 0 : <NUMBER>             rayon de chaque occupation (m)
 * 1 : <NUMBER|STRING|SIDE> faction — passe par le registre, donc 0..7,
 *                          un id ("rhs_faction_vdv") ou east / "AUTO"
 * 2 : <BOOL>               true  : toutes les localisations
 *                          false : environ une sur quatre, au hasard
 * 3 : <NUMBER>             difficulté : densité de chaque occupation
 * 4 : <ARRAY>              types de localisation à retenir
 *
 * À lancer avec spawn :
 *   [300, 0, false, 1, ["NameVillage"]] spawn fnc_hds_presence_hostile;
 *
 * ─────────────────────────────────────────────────────────────
 * ── Ce qui a été réparé en la câblant ──
 *
 * Comme fnc_hds_missions, le corps existait dans
 * hdssystem\fonctions\fonctions\ops-presence-hostile.sqf sans être
 * assigné à aucun nom, alors que le générateur savait déjà l'appeler.
 *
 *   1. Tout partait sur la même image. La boucle lançait une
 *      occupation par localisation d'affilée — sur une carte un peu
 *      fournie, cela veut dire des dizaines de spawns simultanés, et
 *      un gel au démarrage. On étale d'une seconde entre chaque.
 *
 *   2. Le rayon de recherche était 50 km depuis le coin [0,0,0].
 *      C'est worldSize depuis le centre : juste sur n'importe quelle
 *      carte, et sans ramasser deux fois le même lieu.
 *
 *   3. Aucune trace. Avec « une sur quatre au hasard », il était
 *      impossible de savoir si la fonction avait fait quelque chose.
 *      Elle dit maintenant combien de lieux elle a retenus.
 *
 * ── Attention à ce que ça coûte ──
 * Avec le paramètre 2 à true, c'est une occupation par localisation de
 * la carte. Sur Stratis cela reste tenable ; sur une grande carte, et
 * avec une difficulté élevée, c'est de quoi saturer un serveur. Le
 * journal annonce le nombre avant de commencer, justement pour qu'on
 * puisse le voir venir.
 */

if (!isServer) exitWith {};

params [
    ["_rayon",            300],
    ["_faction",          east],
    ["_toujours",         false],
    ["_difficulte",       1],
    ["_typeLocalisation", ["NameVillage"]]
];

if (!canSuspend) exitWith {
    ["ERREUR", "PRESENCE", "fnc_hds_presence_hostile doit etre lancee avec spawn, pas call"]
        call hds_fnc_log;
};

private _localisations = nearestLocations [
    [worldSize / 2, worldSize / 2, 0],
    _typeLocalisation,
    worldSize
];

if (_localisations isEqualTo []) exitWith {
    ["ALERTE", "PRESENCE", format [
        "aucune localisation de type %1 sur %2 - rien a peupler",
        _typeLocalisation, worldName
    ]] call hds_fnc_log;
};

// Tirage d'abord, pour pouvoir annoncer le total avant de dépenser
// quoi que ce soit.
private _retenues = if (_toujours) then {
    _localisations
} else {
    _localisations select { (selectRandom [0, 1, 2, 3]) isEqualTo 1 }
};

["INFO", "PRESENCE", format [
    "%1 lieu(x) retenu(s) sur %2 - rayon %3 m - faction %4 - densite %5",
    count _retenues, count _localisations, _rayon, _faction, _difficulte
]] call hds_fnc_log;

{
    private _pos = locationPosition _x;

    [_pos, _difficulte, _faction, _rayon, false] spawn fnc_hds_occupations;
    [_pos, _rayon, _faction, 1, 1] spawn fnc_tactique_plannification;

    // Une seconde entre deux lieux : fnc_hds_occupations attend de
    // toute façon que le registre soit prêt, mais le spawn des groupes
    // lui-même coûte cher. Les étaler évite le gel de démarrage.
    sleep 1;
} forEach _retenues;

["INFO", "PRESENCE", format ["presence hostile semee sur %1 lieu(x)", count _retenues]]
    call hds_fnc_log;

true
