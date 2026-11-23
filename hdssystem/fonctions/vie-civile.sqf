/*
 * fnc_hds_vie_civile
 * ─────────────────────────────────────────────────────────────
 * La vie civile SUIT LES JOUEURS. Partout où ils vont, s'il y a des
 * maisons autour, il y a des habitants et des voitures garées. Ailleurs
 * il n'y a rien, et rien ne tourne.
 *
 * Le trafic routier est confié au script d'Engima, qui suit déjà les
 * joueurs de la même façon.
 *
 * 0 : <NUMBER> densité (habitants ajoutés, et compte du trafic)
 * 1 : <BOOL>   peupler les abords des joueurs
 * 2 : <ARRAY>  conservé pour les anciens appels, sans effet
 * 3 : <NUMBER> rayon d'ambiance autour d'un joueur (m)
 * 4 : <NUMBER> conservé pour les anciens appels, sans effet
 * 5 : <NUMBER> distance d'oubli des habitants (m)
 *
 * À lancer avec spawn :
 *   [] spawn fnc_hds_vie_civile;
 *
 * ─────────────────────────────────────────────────────────────
 * ── Pourquoi cette version est la bonne ──
 * Les précédentes partaient des localisations déclarées par la carte :
 * on relevait les NameCity et NameVillage, et on peuplait celles dont
 * un joueur s'approchait.
 *
 * Sur Stratis, les deux seules NameVillage sont au nord-ouest. En
 * jouant au sud, on ne croisait donc strictement personne — et le
 * système n'avait rien à se reprocher, il faisait exactement ce qu'on
 * lui demandait. Le modèle était faux, pas le code.
 *
 * Dépendre du nommage d'une carte, c'est dépendre de quelque chose
 * qu'on ne maîtrise pas. On regarde maintenant une seule chose : y
 * a-t-il des maisons autour du joueur ? Si oui, on peuple. Ça marche
 * sur n'importe quelle carte, nommée ou non, y compris un hameau sans
 * nom ou un camp militaire.
 *
 * ── Le cycle, toutes les huit secondes ──
 *   1. OUBLI    tout civil d'ambiance dont le joueur le plus proche est
 *               au-delà de la distance d'oubli est supprimé. Plus
 *               personne connecté : on vide entièrement.
 *   2. SUIVRE   pour chaque joueur : s'il y a assez de maisons autour
 *               et pas assez de civils, on peuple sur place. Un délai
 *               par secteur évite de recommencer à chaque passage.
 *   3. GARER    des voitures vides le long des rues habitées.
 *
 * Seuls les civils marqués « hds_civil_ambiance » sont balayés. Un
 * otage, un VIP, un civil posé par une mission, et les véhicules
 * d'Engima — qui gère les siens — ne portent pas cette marque.
 *
 * Le réglage CBA « Population civile » décoché arrête tout.
 */

if (!isServer) exitWith {};

params [
    ["_densite",          8],
    ["_peupler",          true],
    ["_inutilise1",       []],
    ["_rayonAmbiance",    300],
    ["_inutilise2",       500],
    ["_distanceOubli",    1200]
];

if (!canSuspend) exitWith {
    ["ERREUR", "CIVILS", "fnc_hds_vie_civile doit etre lancee avec spawn, pas call"]
        call hds_fnc_log;
};

// Le registre est rempli de façon asynchrone au démarrage.
if (!hds_factions_pret) then { waitUntil { hds_factions_pret } };

// ─── Une seule faction civile, pour tout ───
// Habitants, voitures garées et trafic tirent leurs classes du même id :
// une rue dont les passants et les automobilistes ne sont pas du même
// peuple, ça se remarque.
([civilian] call hds_fnc_factionResoudre) params ["_idCiv", "_sideCiv"];

private _classesHom = [_idCiv] call hds_fnc_factionHommes;

["INFO", "CIVILS", format [
    "population civile retenue : %1 - %2 homme(s) dans le registre",
    (["aucune", _idCiv] select (_idCiv != "")), count _classesHom
]] call hds_fnc_log;

if (isNil "hds_civils_densite") then { hds_civils_densite = _densite };

// ═══════════════════════════════════════════════════════════
// LE TRAFIC : ON PASSE LA MAIN
// ═══════════════════════════════════════════════════════════
if (missionNamespace getVariable ["hds_civils_actifs", true]) then {
    if (isNil "fnc_engima_traffic") then {
        ["ALERTE", "CIVILS",
         "trafic : le script Engima n'est pas charge - aucune circulation"
        ] call hds_fnc_log;
    } else {
        [] spawn fnc_engima_traffic;
    };
};

// ═══════════════════════════════════════════════════════════
// OUTILS
// ═══════════════════════════════════════════════════════════

// Tout ce que cette fonction a fait naître, et rien d'autre.
private _fnAmbiance = {
    (allUnits + vehicles) select { _x getVariable ["hds_civil_ambiance", false] }
};

// Vrai si aucun joueur n'est à moins de _d mètres.
private _fnLoin = {
    params ["_objet", "_joueurs", "_d"];
    private _proche = false;
    { if ((_objet distance2D _x) < _d) exitWith { _proche = true } } forEach _joueurs;
    !_proche
};

// Supprime un civil et, s'il conduit, son véhicule avec l'équipage.
private _fnSupprimer = {
    params ["_objet"];
    private _v = if (_objet isKindOf "Man") then { vehicle _objet } else { _objet };

    if (!(_v isEqualTo _objet) || { !(_v isKindOf "Man") }) then {
        { deleteVehicle _x } forEach (crew _v);
        deleteVehicle _v;
    } else {
        deleteVehicle _objet;
    };
};

// Secteurs déjà traités récemment : [position, instant de reprise].
// Sans ça, un joueur immobile relancerait le peuplement toutes les huit
// secondes au même endroit.
private _recents = [];

["INFO", "CIVILS", format [
    "vie civile en service - ambiance dans %1 m autour des joueurs, oubli a %2 m",
    _rayonAmbiance, _distanceOubli
]] call hds_fnc_log;

// ═══════════════════════════════════════════════════════════
// LE CYCLE
// ═══════════════════════════════════════════════════════════
while {true} do {

    private _actif   = missionNamespace getVariable ["hds_civils_actifs", true];
    private _voulu   = round (missionNamespace getVariable ["hds_civils_densite", _densite]);
    private _joueurs = allPlayers select {
        alive _x && { !(_x isKindOf "HeadlessClient_F") }
    };

    // ─── 1. OUBLI ───
    if (!_actif || { _joueurs isEqualTo [] }) then {

        private _ambiance = call _fnAmbiance;

        if !(_ambiance isEqualTo []) then {
            { [_x] call _fnSupprimer } forEach _ambiance;
            _recents = [];

            ["INFO", "CIVILS", format [
                "%1 civil(s) d'ambiance retire(s) - %2",
                count _ambiance,
                ["aucun joueur connecte", "reglage decoche"] select (!_actif)
            ]] call hds_fnc_log;
        };

    } else {

        {
            if ([_x, _joueurs, _distanceOubli] call _fnLoin) then {
                [_x] call _fnSupprimer;
            };
        } forEach (call _fnAmbiance);

        // Les groupes vidés par le balayage ne servent plus à rien.
        {
            if ((side _x isEqualTo civilian) && { (units _x) isEqualTo [] }) then {
                deleteGroup _x;
            };
        } forEach allGroups;

        // Oublier les secteurs dont le délai est passé.
        _recents = _recents select { (_x select 1) > time };

        // ─── 2. SUIVRE LES JOUEURS ───
        if (_peupler) then {
            {
                private _p = getPosATL _x;

                // Déjà traité il y a peu ?
                private _recent = false;
                {
                    if ((_p distance2D (_x select 0)) < (_rayonAmbiance * 0.8)) exitWith {
                        _recent = true;
                    };
                } forEach _recents;

                if (!_recent) then {

                    // Combien de civils d'ambiance autour de lui.
                    private _civils = allUnits select {
                        _x getVariable ["hds_civil_ambiance", false]
                        && { alive _x }
                        && { (_x distance2D _p) < _rayonAmbiance }
                    };

                    if ((count _civils) < 6) then {

                        private _maisons = nearestObjects [_p, ["House"], _rayonAmbiance];

                        if ((count _maisons) >= 5) then {

                            [_p, -1, _rayonAmbiance, _idCiv, false]
                                spawn fnc_occupations_civil_init;

                            [_p, _rayonAmbiance, -1, _idCiv]
                                spawn hds_fnc_voituresGarees;

                            _recents pushBack [_p, time + 90];

                            ["INFO", "CIVILS", format [
                                "ambiance posee autour de [%1,%2] - %3 maisons, %4 civil(s) deja sur place",
                                round (_p select 0), round (_p select 1),
                                count _maisons, count _civils
                            ]] call hds_fnc_log;
                        } else {
                            // Rien à peupler ici : on note quand même le
                            // passage, sinon on recompte les maisons
                            // toutes les huit secondes en rase campagne.
                            _recents pushBack [_p, time + 60];
                        };
                    };
                };

            } forEach _joueurs;
        };
    };

    sleep 8;
};
