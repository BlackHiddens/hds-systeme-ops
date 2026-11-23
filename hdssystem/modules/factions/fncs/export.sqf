/*
 * hds_fnc_factionsExport
 * ─────────────────────────────────────────────────────────────
 * Rend le registre en JSON, pour qu'un outil hors Arma puisse savoir
 * quelles factions existent réellement sur CE serveur.
 *
 * 0 : <STRING> filtre de camp : "" (tous), "EAST", "WEST", "INDEP", "CIV"
 *
 * Retourne : <STRING> du JSON strict, directement consommable par
 *            JSON.parse côté navigateur.
 *
 * Forme produite :
 *   {
 *     "hds": 1,
 *     "carte": "Stratis",
 *     "mission": "NewHDS",
 *     "date": "2026-11-19 20:30:00",
 *     "mods": ["CBA","RHS-AFRF"],
 *     "factions": [
 *       {"id":"OPF_F","nom":"CSAT","camp":"EAST",
 *        "g":["SQUAD","FIRETEAM"],"v":["CAMION","LEGER"]}
 *     ]
 *   }
 *
 * Les rôles sont donnés sans leur effectif : le générateur a besoin de
 * savoir si une faction PEUT fournir un blindé, pas combien elle en a.
 * Ça divise le poids du presse-papier par deux.
 *
 * CÔTÉ SERVEUR : le registre n'existe que là.
 *
 * ── Note sur l'assainissement ──
 * Un guillemet dans un nom de faction casserait le JSON, on le remplace
 * par une apostrophe. Un antislash le casserait aussi, mais aucun nom
 * affichable n'en contient en pratique et le traiter en SQF demande des
 * contorsions : si ça arrive un jour, ça se verra au JSON.parse.
 */

params [["_filtre", ""]];

if (!hds_factions_pret) exitWith {
    "{""hds"":1,""erreur"":""registre pas encore pret""}"
};

private _echappe = { (_this splitString """") joinString "'" };
private _pad = { if (_this < 10) then { "0" + str _this } else { str _this } };

// ─── Date ───
private _st = systemTime;
private _date = if (count _st >= 6) then {
    format ["%1-%2-%3 %4:%5:%6",
        _st select 0,
        (_st select 1) call _pad, (_st select 2) call _pad,
        (_st select 3) call _pad, (_st select 4) call _pad, (_st select 5) call _pad]
} else { "?" };

// ─── Mods détectés ───
private _mods = [];
{
    _x params ["_var", "_nom"];
    // getVariable avec defaut suffit : pas besoin d'un isNil sur un nom
    // porte par une variable, dont le comportement est ambigu.
    if (missionNamespace getVariable [_var, false]) then {
        _mods pushBack ("""" + _nom + """");
    };
} forEach [
    ["cbaestactive", "CBA"], ["aceestactive", "ACE"],
    ["opforactive", "ProjectOPFOR"], ["afrfactive", "RHS-AFRF"],
    ["usafactive", "RHS-USAF"], ["grefactive", "RHS-GREF"],
    ["safactive", "RHS-SAF"]
];

// ─── Factions ───
private _filtreMaj = toUpper _filtre;
private _parties = [];

{
    private _f = _y;
    private _camp = _f get "sideNom";

    if (_filtreMaj isEqualTo "" || { _filtreMaj isEqualTo _camp }) then {

        private _g = [];
        { _g pushBack ("""" + _x + """") } forEach (keys (_f get "groupes"));

        private _v = [];
        { _v pushBack ("""" + _x + """") } forEach (keys (_f get "veh"));

        // Une faction sans rien d'exploitable n'intéresse pas le générateur
        if (!(_g isEqualTo []) || { !(_v isEqualTo []) }) then {
            _parties pushBack format [
                "{""id"":""%1"",""nom"":""%2"",""camp"":""%3"",""g"":[%4],""v"":[%5]}",
                (_f get "id")  call _echappe,
                (_f get "nom") call _echappe,
                _camp,
                _g joinString ",",
                _v joinString ","
            ];
        };
    };
} forEach hds_factions;

// ─── Relief de la carte ───
// Il part avec le registre : un seul bouton en jeu, un seul collage
// dans le générateur, et celui-ci peut dessiner la carte du serveur
// au lieu d'afficher des coordonnées nues.
//
// Sous hds_fnc_proteger : échantillonner 9216 points fait appel au
// moteur de terrain, et un export de factions ne doit pas tomber
// parce qu'une carte moddée répond de travers. Sans relief, le
// générateur retombe sur son plan schématique.
private _terrain = "";
([{ [] call hds_fnc_terrainExport }, "FACTIONS"] call hds_fnc_proteger) params ["_okT", "_sortieT"];
if (_okT) then { _terrain = _sortieT param [0, ""] };
if (!(_terrain isEqualTo "")) then { _terrain = "," + _terrain };

private _json = format [
    "{""hds"":1,""carte"":""%1"",""mission"":""%2"",""date"":""%3"",""mods"":[%4],""factions"":[%5]%6}",
    worldName call _echappe,
    briefingName call _echappe,
    _date,
    _mods joinString ",",
    _parties joinString ",",
    _terrain
];

// Toujours dans le RPT : outils\extraire-log.ps1 peut le récupérer même
// sans personne en jeu, et c'est la voie pour un serveur dédié.
diag_log format ["[HDS][FACTIONS_JSON]%1", _json];

["INFO", "FACTIONS", format [
    "Export JSON : %1 factions, %2 caracteres", count _parties, count _json
]] call hds_fnc_log;

_json
