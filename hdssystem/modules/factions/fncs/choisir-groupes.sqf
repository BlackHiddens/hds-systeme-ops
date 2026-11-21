/*
 * hds_fnc_factionGroupes
 * ─────────────────────────────────────────────────────────────
 * Rend TOUTES les entrées CfgGroups d'une faction qui répondent à
 * une intention, avec repli garanti.
 *
 * 0 : <NUMBER|STRING|SIDE> faction (voir hds_fnc_factionResoudre)
 * 1 : <STRING> intention : GARNISON, PATROUILLE, RECON, ASSAUT,
 *              SUPPORT, MOTORISE, MECANISE, BLINDE, AIR, NAVAL
 *              (ou directement un nom de rôle)
 *
 * Retourne : <ARRAY> entrées CfgGroups, [] si rien
 *
 * Chaîne de repli :
 *   1. les rôles de l'intention, dans la faction résolue
 *   2. les mêmes rôles dans les autres factions du même camp,
 *      les factions vanilla en premier
 *   3. []  + trace RPT
 *
 * C'est la liste complète, et pas un tirage, parce que les
 * occupations varient la composition d'une équipe à l'autre.
 */

params [["_faction", east], ["_intention", "GARNISON"]];

if (!hds_factions_pret) then {
    diag_log "[HDS][FACTIONS] /!\ Registre pas encore pret - attendre hds_factions_pret";
};

([_faction] call hds_fnc_factionResoudre) params ["_id", "_side"];

if (_id isEqualTo "") exitWith {
    diag_log format ["[HDS][FACTIONS] Aucune faction resolue pour %1", _faction];
    []
};

private _f = hds_factions get _id;
if (isNil "_f") exitWith {
    diag_log format ["[HDS][FACTIONS] Faction inconnue : %1", _id];
    []
};

// Une intention, ou directement un nom de rôle
private _intMaj = toUpper _intention;
private _roles  = hds_factions_intentions getOrDefault [_intMaj, []];
if (_roles isEqualTo []) then {
    if (_intMaj in hds_factions_roles) then {
        _roles = [_intMaj];
    } else {
        diag_log format ["[HDS][FACTIONS] Intention inconnue : %1 - repli GARNISON", _intention];
        _roles = hds_factions_intentions get "GARNISON";
    };
};

private _trouve = [];

// ─── 1) Dans la faction résolue ───
private _parRole = _f get "groupes";
{
    private _l = _parRole getOrDefault [_x, []];
    if (count _l > 0) exitWith { _trouve = +_l };
} forEach _roles;

if !(_trouve isEqualTo []) exitWith { _trouve };

// ─── 2) Autres factions du même camp, vanilla d'abord ───
private _sideNom = _f get "sideNom";
private _autres  = (hds_factions_par_side getOrDefault [_sideNom, []]) - [_id];
_autres = (_autres select { _x in hds_factions_vanilla })
        + (_autres select { !(_x in hds_factions_vanilla) });

private _idRepli = "";
{
    private _idAutre = _x;
    private _g = hds_factions get _idAutre;
    if (!isNil "_g") then {
        private _pr = _g get "groupes";
        {
            private _l = _pr getOrDefault [_x, []];
            if (count _l > 0) exitWith { _trouve = +_l };
        } forEach _roles;
    };
    if !(_trouve isEqualTo []) exitWith { _idRepli = _idAutre };
} forEach _autres;

if (_trouve isEqualTo []) then {
    diag_log format ["[HDS][FACTIONS] Rien trouve pour %1 / %2", _id, _intention];
} else {
    if (hdssysteme && { _idRepli != "" }) then {
        diag_log format [
            "[HDS][FACTIONS] Repli groupe : %1 / %2 servi par %3 (%4 compositions)",
            _id, _intention, _idRepli, count _trouve
        ];
    };
};

_trouve
