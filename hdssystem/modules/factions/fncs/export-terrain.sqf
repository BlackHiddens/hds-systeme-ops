/*
 * hds_fnc_terrainExport
 * ─────────────────────────────────────────────────────────────
 * Rend la forme du terrain en JSON, pour que le générateur web puisse
 * DESSINER la carte du serveur au lieu de montrer des chiffres.
 *
 * Retourne : <STRING> un fragment JSON, sans accolades extérieures,
 *            destiné à être inséré dans l'export du registre.
 *            "" si quelque chose a échoué — l'export reste valide.
 *
 * ── Pourquoi pas une image ──
 * Aucune commande SQF ne sait extraire l'image satellite d'une carte.
 * Et même si c'était possible, il faudrait l'embarquer : une capture
 * d'Altis lisible pèse des centaines de kilo-octets, à coller dans un
 * presse-papier et à garder dans le navigateur.
 *
 * On exporte donc la seule chose qui compte pour reconnaître une
 * carte : son RELIEF, échantillonné sur une grille. getTerrainHeightASL
 * existe partout, sur toutes les cartes, moddées comprises. Une hauteur
 * négative, c'est la mer : le trait de côte sort tout seul.
 *
 * ── Le poids ──
 * 96 × 96 = 9216 points. Un point par caractère, pas un nombre suivi
 * d'une virgule : chaque hauteur est quantifiée sur 64 niveaux et
 * écrite avec un caractère de l'alphabet base64. 9216 octets, soit
 * moins d'un quart du registre de factions avec RHS chargé.
 *
 * ── La forme produite ──
 *   "terrain":{
 *     "taille":8192,          largeur de la carte en mètres
 *     "g":96,                 côté de la grille
 *     "hmax":480,             altitude la plus haute rencontrée
 *     "h":"AAAABCD...",       g*g caractères, voir ci-dessous
 *     "lieux":[{"n":"Agia Marina","t":"NameVillage","x":4506,"y":5729,"r":180}]
 *   }
 *
 * Lecture de "h" : index = iy * g + ix, avec ix d'ouest en est et
 * iy du SUD vers le nord — le sens d'Arma, pas celui du SVG. Le
 * générateur retourne l'image lui-même ; c'est son problème, pas celui
 * du serveur. Le caractère 'A' (valeur 0) vaut MER. De 1 à 63 :
 * altitude = valeur / 63 * hmax.
 *
 * CÔTÉ SERVEUR, appelé par hds_fnc_factionsExport.
 */

private _alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
private _g     = 96;
private _taille = worldSize;

if (_taille <= 0) exitWith {
    ["ALERTE", "TERRAIN", "worldSize nul - terrain non exporte"] call hds_fnc_log;
    ""
};

// ─── Échantillonnage ───
// Au centre de chaque cellule : un point pris au coin donnerait un
// décalage d'une demi-cellule vers le sud-ouest, visible sur le trait
// de côte d'une petite carte.
private _pas = _taille / _g;
private _brut = [];
_brut resize (_g * _g);

private _hmax = 1;

for "_iy" from 0 to (_g - 1) do {
    private _y = (_iy + 0.5) * _pas;
    for "_ix" from 0 to (_g - 1) do {
        private _h = getTerrainHeightASL [(_ix + 0.5) * _pas, _y, 0];
        _brut set [_iy * _g + _ix, _h];
        if (_h > _hmax) then { _hmax = _h };
    };
};

// ─── Quantification ───
// Un tableau de caractères puis joinString : concaténer 9216 fois dans
// une même chaîne recopie la chaîne entière à chaque tour.
private _chars = [];
_chars resize (_g * _g);

{
    private _v = if (_x < 0) then {
        0
    } else {
        // 1 minimum : le niveau 0 est réservé à la mer, sinon une plage
        // à l'altitude zéro passerait pour de l'eau.
        1 max (round ((_x / _hmax) * 63))
    };
    _chars set [_forEachIndex, _alpha select [_v, 1]];
} forEach _brut;

// ─── Lieux nommés ───
// Les villes donnent l'échelle et permettent de se repérer : sans
// elles, un trait de côte reste une tache. On garde les plus grandes,
// un plafond pour que le presse-papier ne gonfle pas sur une carte
// généreuse en hameaux.
private _echappe = { (_this splitString """") joinString "'" };

private _locs = nearestLocations [
    [_taille / 2, _taille / 2, 0],
    ["NameCity", "NameVillage", "NameLocal", "Airport", "NameMarine"],
    _taille
];

// Deux tableaux parallèles, et le tri ne porte que sur des nombres :
// « sort » exige des éléments homogènes, un [nombre, texte, texte,
// nombre, nombre] le ferait échouer sur certaines versions.
private _items = [];
private _rangs = [];

{
    private _r = 60;
    private _s = size _x;
    if (_s isEqualType [] && { count _s >= 1 }) then {
        _r = round ((_s select 0) max (_s param [1, 0]));
    };
    private _p = locationPosition _x;
    private _n = text _x;
    if (_n isEqualTo "") then { _n = type _x };

    _rangs pushBack [_r, count _items];
    _items pushBack format [
        "{""n"":""%1"",""t"":""%2"",""x"":%3,""y"":%4,""r"":%5}",
        _n call _echappe, type _x,
        round (_p select 0), round (_p select 1), _r
    ];
} forEach _locs;

// Décroissant par taille : si le plafond coupe, il coupe les hameaux.
_rangs sort false;

private _lieux = [];
{
    if (count _lieux >= 90) exitWith {};
    _lieux pushBack (_items select (_x select 1));
} forEach _rangs;

["INFO", "TERRAIN", format [
    "Terrain exporte : %1 (%2 m), grille %3, %4 lieux, %5 caracteres de relief",
    worldName, round _taille, _g, count _lieux, _g * _g
]] call hds_fnc_log;

format [
    """terrain"":{""taille"":%1,""g"":%2,""hmax"":%3,""h"":""%4"",""lieux"":[%5]}",
    round _taille,
    _g,
    round _hmax,
    _chars joinString "",
    _lieux joinString ","
]
