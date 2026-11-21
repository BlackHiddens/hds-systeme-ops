/*
 * hdssystem\init-systeme.sqf
 * ─────────────────────────────────────────────────────────────
 * Chargement du système HDS, côté serveur.
 *
 *   ╔═══════════════════════════════════════════════════════╗
 *   ║  NE PAS ÉCRASER CE FICHIER.                           ║
 *   ║  C'est lui qui compile les modules. Ta mission, elle,  ║
 *   ║  est dans hdssystem\init-scenario.sqf, qui ne contient ║
 *   ║  que ça — et que tu peux donc remplacer en entier.    ║
 *   ╚═══════════════════════════════════════════════════════╝
 *
 * ── Pourquoi ce fichier existe ──
 * Le générateur web dit « à coller dans init-scenario.sqf, à la place
 * de son contenu ». Or ce fichier-là portait aussi les #include des
 * modules : coller la mission générée par-dessus effaçait tout le
 * système. Le défaut était de conception, pas d'usage. Les deux rôles
 * sont donc séparés :
 *
 *   initserver.sqf      setup serveur, puis appelle →
 *   init-systeme.sqf    (ici) compile les modules, puis appelle →
 *   init-scenario.sqf   la mission, et rien d'autre. Jetable.
 *
 * Appelé depuis initserver.sqf par execVM.
 */

if (!isServer) exitWith {};

diag_log "[HDS][SYSTEME] Chargement du systeme...";

// ─── Arsenaux (après connexion des joueurs) ───
[] spawn {
    waitUntil { count allPlayers > 0 };
    sleep 5;
    [sontdesarsenales] spawn fnc_hds_arsenaux;
    diag_log "[HDS][SYSTEME] Arsenaux initialises";
};

// ─── Groupes OPFOR : placés par le joueur dans l'éditeur ───
// Le système s'additionne à la mission : il ne spawne rien de lui-même ici.

// ─── Module Factions : registre dynamique lu dans la config du serveur ───
// En premier : les autres modules s'appuieront dessus pour ne plus
// coder aucun classname de faction en dur.
#include "modules\factions\h-init.sqf"
diag_log "[HDS][SYSTEME] Factions compilees";

// ─── Fonctions HDS : Occupations (fnc_hds_occupations, fnc_occupations_init...) ───
#include "modules\occupations\h-init.sqf"
diag_log "[HDS][SYSTEME] Occupations compilees";

// ─── Fonctions HDS : Missions (fnc_objectif_*) ───
#include "modules\missions\h-init.sqf"
diag_log "[HDS][SYSTEME] Missions compilees";

// ─── Module Tactiques HDS (renfort, contre-attaque, insertion) ───
#include "modules\tactiques\h-init.sqf"
diag_log "[HDS][SYSTEME] Tactiques compilees";

// ─── Module Scénario (fnc_scenario_*) ───
// Les onze tâches que produit le générateur : otage, collecter,
// détruire, sécuriser, renfort… plus fnc_scenario_init.
#include "modules\scenario\h-init.sqf"
diag_log "[HDS][SYSTEME] Scenario compile";

diag_log "[HDS][SYSTEME] Systeme pret";

// ═══════════════════════════════════════════════════════════
// LA MISSION
// ═══════════════════════════════════════════════════════════
// Toutes les fonctions HDS sont compilées : init-scenario.sqf peut
// appeler fnc_hds_occupations, fnc_scenario_*, fnc_tactique_*,
// fnc_renfort_init… sans se soucier de l'ordre.
//
// Le fichier peut être vide, ou absent : on le dit dans le journal au
// lieu de laisser le moteur cracher une erreur de script. Un serveur
// sans mission générée reste un serveur qui démarre.
//
// ── Garde-fou : les fonctions que le générateur sait appeler mais que
//    ce dépôt n'a pas ──
// Une variable indéfinie n'est pas une ligne perdue en SQF : elle
// AVORTE le script entier. C'est ce qui s'était passé avec
// fnc_scenario_init — une seule fonction manquante, et les quatre
// étapes de la mission n'ont jamais tourné. Maintenant que
// init-scenario.sqf est un fichier que l'on remplace à la main, le
// risque est permanent : il suffit de cocher « trafic civil » dans le
// générateur pour produire un appel à fnc_engima_traffic.
//
// On pose donc une fonction bouchon pour chacune : elle écrit une
// alerte lisible dans le journal et rend false. L'étape concernée ne
// fait rien — elle ne faisait rien non plus avant — mais les suivantes
// s'exécutent.
//
// compile format, et non un bloc de code : le SQF ne capture pas les
// variables locales, _x ne serait plus dans la portée à l'appel.
{
    if (isNil _x) then {
        missionNamespace setVariable [_x, compile format [
            "[""ALERTE"", ""SYSTEME"", ""%1 : fonction absente de ce depot, etape ignoree""] call hds_fnc_log; false",
            _x
        ]];
        diag_log format ["[HDS][SYSTEME] Bouchon pose sur %1", _x];
    };
// La liste s'est vidée au fur et à mesure : fnc_hds_missions et
// fnc_hds_presence_hostile dormaient sans nom dans fonctions\fonctions\
// et sont maintenant assignées, et fnc_engima_traffic a été remplacée
// par fnc_hds_vie_civile, qui fait le même travail depuis le registre
// sans ajouter de dépendance.
//
// fnc_engima_traffic reste ici pour une seule raison : un scénario
// généré AVANT ce changement contient encore « spawn
// fnc_engima_traffic ». Si tu recolles un vieux fichier, il tournera
// quand même, avec une alerte dans le journal plutôt qu'un scénario
// avorté. Le garder coûte une ligne.
} forEach ["fnc_engima_traffic"];

// Le test se fait avec splitString plutôt que regexMatch : c'est la
// dernière chose évaluée avant le lancement de la mission, donc la
// moins bien placée pour tomber en panne. splitString et toString sont
// là depuis toujours ; le préprocesseur retire les commentaires, un
// fichier qui n'a plus que de l'espace rend un tableau vide.
private _mission = preprocessFile "hdssystem\init-scenario.sqf";
private _blancs  = toString [32, 9, 10, 13];

if ((_mission splitString _blancs) isEqualTo []) exitWith {
    ["ALERTE", "SYSTEME",
     "init-scenario.sqf est vide ou absent : le systeme est charge, mais aucune mission n'a ete lancee"
    ] call hds_fnc_log;
};

[] execVM "hdssystem\init-scenario.sqf";
["INFO", "SYSTEME", "init-scenario.sqf lance"] call hds_fnc_log;
