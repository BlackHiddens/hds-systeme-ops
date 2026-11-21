/*
 * hds_fnc_factionDuTerrain
 * ─────────────────────────────────────────────────────────────
 * Déduit la faction à utiliser pour un camp à partir de ce que le
 * créateur de mission a RÉELLEMENT posé dans l'éditeur.
 *
 * C'est le cœur du principe « le script s'additionne à la mission » :
 * tu poses des CSAT, il renforce en CSAT. Tu remplaces par des RHS
 * russes, il renforce en RHS russe. Aucun réglage, aucun index à
 * changer, rien à recompiler.
 *
 * 0 : <SIDE> le camp observé (défaut east)
 *
 * Retourne : <STRING> id de faction, "" si le camp n'existe pas du
 *            tout sur ce serveur
 *
 * Ordre de décision :
 *   1. la faction la plus représentée parmi les unités et véhicules
 *      vivants de ce camp
 *   2. à défaut (rien de posé) : la première faction vanilla connue
 *      du camp
 *   3. à défaut : la première faction connue du camp
 *
 * Le résultat est mis en cache par camp. Vider le cache après avoir
 * modifié la composition de la mission en cours de partie :
 *   hds_factions_cache_terrain = createHashMap;
 */

params [["_camp", east]];

if (isNil "hds_factions_cache_terrain") then {
    hds_factions_cache_terrain = createHashMap;
};

private _sideNom = [_camp] call hds_fnc_factionsSideNom;

// ─── Réglage « Faction forcée » du menu CBA ───
// Il court-circuite la déduction, mais seulement pour SON camp : forcer
// les Russes côté OPFOR ne doit rien changer à ce que reçoit le BLUFOR.
// Lu avant le cache, pour qu'un changement en jeu prenne effet tout de
// suite au lieu d'attendre une purge.
private _forcee = missionNamespace getVariable ["hds_faction_forcee", "AUTO"];
private _idForce = "";

if (_forcee != "AUTO") then {
    private _e = hds_factions_legacy getOrDefault [parseNumber _forcee, []];
    if !(_e isEqualTo []) then {
        if ((_e select 1) isEqualTo _camp) then { _idForce = _e select 0 };
    };
};

if (_idForce != "" && { !isNil { hds_factions get _idForce } }) exitWith {
    if (hdssysteme) then {
        diag_log format ["[HDS][FACTIONS] Camp %1 : faction forcee par reglage = %2", _sideNom, _idForce];
    };
    _idForce
};

private _cache = hds_factions_cache_terrain get _sideNom;
if (!isNil "_cache") exitWith { _cache };

// ─── 1) Ce que la mission a posé ───
private _comptes = createHashMap;

{
    private _cls = typeOf _x;
    if (_cls != "") then {
        private _f = getText (configFile >> "CfgVehicles" >> _cls >> "faction");
        if (_f != "" && { _f != "Default" }) then {

            // Le camp que rend le moteur ne suffit pas : UN VÉHICULE
            // VIDE EST « civilian », quelle que soit son armée. Un camion
            // OPFOR sans équipage, une épave de la mission, un véhicule
            // posé vide dans l'éditeur — tous comptaient comme civils.
            //
            // Résultat : la faction « civile du terrain » devenait une
            // faction militaire, et fnc_hds_vie_civile demandait ses
            // véhicules légers à l'armée. D'où des civils au volant de
            // blindés, ce qui est exactement ce qui se voyait en jeu.
            //
            // On confronte donc la faction déclarée de la classe au camp
            // demandé, via le registre, au lieu de faire confiance à
            // « side ».
            private _reg = hds_factions get _f;

            if (!isNil "_reg" && { (_reg get "sideNom") isEqualTo _sideNom }) then {
                _comptes set [_f, (_comptes getOrDefault [_f, 0]) + 1];
            };
        };
    };
} forEach ((allUnits + vehicles) select { alive _x && { (side _x) isEqualTo _camp } });

private _resultat = "";

if (count _comptes > 0) then {
    // La faction la plus représentée gagne
    private _max = -1;
    {
        if (_y > _max) then { _max = _y; _resultat = _x; };
    } forEach _comptes;

    if (hdssysteme) then {
        diag_log format [
            "[HDS][FACTIONS] Camp %1 : faction deduite du terrain = %2 (%3 entites)",
            _sideNom, _resultat, _max
        ];
    };
} else {
    // ─── 2) et 3) Rien de posé : on prend ce qui existe ───
    private _dispo = hds_factions_par_side getOrDefault [_sideNom, []];
    private _van   = _dispo select { _x in hds_factions_vanilla };

    if (count _van > 0) then {
        _resultat = _van select 0;
    } else {
        if (count _dispo > 0) then { _resultat = _dispo select 0 };
    };

    if (hdssysteme) then {
        diag_log format [
            "[HDS][FACTIONS] Camp %1 : rien de pose, repli sur %2",
            _sideNom, _resultat
        ];
    };
};

// La faction déduite doit exister dans le registre
if (_resultat != "" && { isNil { hds_factions get _resultat } }) then {
    private _dispo = hds_factions_par_side getOrDefault [_sideNom, []];
    private _van   = _dispo select { _x in hds_factions_vanilla };
    _resultat = if (count _van > 0) then { _van select 0 } else {
        if (count _dispo > 0) then { _dispo select 0 } else { "" }
    };
};

hds_factions_cache_terrain set [_sideNom, _resultat];
_resultat
