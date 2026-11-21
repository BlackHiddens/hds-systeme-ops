/*
 * initserver.sqf — NewHDS (Stratis)
 * S'exécute une seule fois côté serveur au démarrage.
 * Setup technique uniquement. Le système est chargé par
 * hdssystem\init-systeme.sqf, qui lance ensuite la mission
 * (hdssystem\init-scenario.sqf).
 */

#include "mes-parametres.sqf"

// ═══════════════════════════════════════════════════════════
// SETUP SERVEUR
// ═══════════════════════════════════════════════════════════

// ─── Simulation dynamique ───
// L'économie de ressources quand personne n'est dans le secteur. Elle
// demande DEUX choses, et seule la seconde était faite :
//
//   1. le système activé pour la mission — c'est cette ligne. Sans
//      elle, les distances ci-dessous et les « enableDynamicSimulation
//      true » posés sur chaque groupe ne font rien du tout ;
//   2. chaque entité marquée. C'est fait aux neuf endroits où le
//      système crée des groupes (occupations, civils, renforts,
//      miradors, missions aléatoires).
//
// mission.sqm ne porte pas l'attribut Eden correspondant, donc rien
// ne l'activait : tout tournait à pleine simulation.
enableDynamicSimulationSystem true;

"Group"        setDynamicSimulationDistance 1500;
"Vehicle"      setDynamicSimulationDistance 1500;
"EmptyVehicle" setDynamicSimulationDistance 50;

setTimeMultiplier 1;

// ─── Relations de faction ───
independent setFriend [east, 1];
east setFriend [independent, 1];
west setFriend [east, 0];
east setFriend [west, 0];
independent setFriend [west, 0];
west setFriend [independent, 0];
civilian setFriend [west, 1];
civilian setFriend [east, 1];
civilian setFriend [independent, 1];

// ─── Objets de base reposés au sol ───
// Dans l'éditeur ils sont placés à l'altitude du groupe joueur. Quelques
// mètres de dénivelé suffisent à les faire flotter ou s'enfoncer : on les
// recale une fois le terrain chargé. Protégé, parce qu'un nom absent de
// mission.sqm ne doit pas emporter tout initserver.
[] spawn {
    private _objets = sontdesarsenales + sontdeslieudesoin + sontdespostesdecommunications
                    + [tableau_alpha_0];
    {
        private _o = _x;
        [
            {
                params ["_obj"];
                private _p = getPosATL _obj;
                _obj setPosATL [_p select 0, _p select 1, 0];
                _obj setVectorUp surfaceNormal (getPos _obj);
            },
            "BASE",
            [_o]
        ] call hds_fnc_proteger;
    } forEach _objets;

    ["INFO", "BASE", format ["%1 objet(s) de base reposes au sol", count _objets]] call hds_fnc_log;
};

// ─── Point de respawn ───
[] spawn {
    waitUntil { count allPlayers > 0 };
    private _joueur = selectRandom allPlayers;
    waitUntil { (getPos _joueur) distance [0,0,0] > 5 };
    private _posBase = getPos _joueur;
    [west, _posBase, (hdsnombase select 0)] call BIS_fnc_addRespawnPosition;
    diag_log format ["[HDS] Respawn créé en [%1,%2]", round (_posBase select 0), round (_posBase select 1)];
};

// ─── Zeus ───
[] spawn {
    waitUntil { count allPlayers > 0 };
    sleep 3;
    {
        if (getPlayerUID _x in hds_administrateurs) then {
            private _zeus = (createGroup sideLogic) createUnit ["ModuleCurator_F", [0,0,0], [], 0, "NONE"];
            _zeus setVariable ["BIS_fnc_initModules_disableAutoActivation", false, true];
            _zeus setVariable ["Owner", getPlayerUID _x, true];
            _zeus synchronizeObjectsAdd [_x];
            _x assignCurator _zeus;
            [format ["[HDS] Zeus assigné à %1", name _x]] remoteExecCall ["systemChat", 0];
        };
    } forEach allPlayers;
};

// ═══════════════════════════════════════════════════════════
// SYSTÈME PUIS SCÉNARIO
// ═══════════════════════════════════════════════════════════
// Un seul point d'entrée : init-systeme.sqf compile les modules, puis
// lance hdssystem\init-scenario.sqf, qui ne contient que la mission.
// C'est ce découpage qui permet d'écraser le scénario avec la sortie
// du générateur sans emporter le système avec.

[] execVM "hdssystem\init-systeme.sqf";

diag_log "[HDS] initserver.sqf terminé";
