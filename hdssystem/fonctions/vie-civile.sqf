/*
 * fnc_hds_vie_civile
 * ─────────────────────────────────────────────────────────────
 * La vie civile SUIT LES JOUEURS. Partout où ils vont, s'il y a des
 * maisons autour, il y a des habitants et des voitures garées. Ailleurs
 * il n'y a rien, et rien ne tourne.
 *
 * Le trafic routier est confié au script d'Engima, qui suit déjà les
 * joueurs de la même façon. Engima n'est pas exposé au scénario : il
 * est entièrement piloté d'ici, et tout ce qui le règle passe par les
 * paramètres ci-dessous.
 *
 * 0 : <NUMBER> densité du trafic — nombre de véhicules civils
 *              entretenus autour des joueurs. 0 : aucune circulation.
 *              -1 : prendre le curseur du menu CBA.
 * 1 : <NUMBER> densité des habitants — civils ajoutés dans chaque
 *              agglomération, en plus de ceux déduits des maisons.
 *              -1 : la moitié de la densité du trafic.
 * 2 : <BOOL>   poser des habitants et des voitures garées
 * 3 : <NUMBER> rayon d'ambiance autour d'un joueur (m)
 * 4 : <NUMBER> portée du trafic (m) — distance maximale d'apparition
 *              des véhicules. -1 : prendre le curseur du menu CBA.
 * 5 : <NUMBER> distance d'oubli des civils (m)
 * 6 : <NUMBER> distance minimale d'apparition (m) — aucun habitant ni
 *              voiture garée ne naît plus près d'un joueur que ça, ni
 *              dans son champ de vision. -1 : la moitié du rayon
 *              d'ambiance.
 *
 * À lancer avec spawn :
 *   [] spawn fnc_hds_vie_civile;                       // tout par défaut
 *   [12, 6, true, 500, 600, 1400, 250] spawn fnc_hds_vie_civile;
 *
 * ─────────────────────────────────────────────────────────────
 * ── Le scénario décide, pas le menu ──
 * Tout ce qui règle la vie civile doit pouvoir s'écrire dans
 * init-scenario.sqf, donc sortir du générateur : celui qui fabrique une
 * mission n'ouvre jamais hdssystem\. Un nombre qui n'existe que dans le
 * menu CBA est un nombre que le générateur ne peut pas produire.
 *
 * Or les deux curseurs CBA écrasaient les paramètres de cette fonction,
 * et ce n'était pas un hasard : dans CBA, le nom d'un réglage EST le nom
 * de la variable, et CBA la réécrit lui-même. Vérifié dans la source du
 * mod, cba_settings\XEH_preInit.sqf, événement refreshSetting :
 *
 *     missionNamespace setVariable [_setting, _value];
 *     ...
 *     (_this select 0) call (_this select 1);   // puis le script du réglage
 *
 * Ce rafraîchissement a lieu au postInit (XEH_postInit.sqf appelle
 * refreshAllSettings), à chaque chargement de sauvegarde
 * (addMissionEventHandler "Loaded"), et à chaque diffusion d'un réglage.
 * Écrire hds_civils_densite depuis le scénario, c'est donc écrire dans
 * une case qui appartient à CBA : il la reprend quand il veut.
 *
 * D'où le découpage. Nos valeurs vivent dans NOS variables :
 *
 *     hds_vie_densite    hds_vie_habitants    hds_vie_portee
 *
 * Le scénario les pose, et le curseur CBA n'est plus la source mais une
 * télécommande : on ne le suit que lorsque sa valeur CHANGE, c'est-à-dire
 * quand quelqu'un l'a bougé en jeu. Un rafraîchissement rend la même
 * valeur, ne change rien, et le choix du scénario tient.
 *
 * ── Pourquoi on suit les joueurs et pas les lieux nommés ──
 * Les versions précédentes partaient des localisations déclarées par la
 * carte : on relevait les NameCity et NameVillage, et on peuplait celles
 * dont un joueur s'approchait.
 *
 * Sur Stratis, les deux seules NameVillage sont au nord-ouest. En jouant
 * au sud, on ne croisait donc strictement personne — et le système
 * n'avait rien à se reprocher, il faisait exactement ce qu'on lui
 * demandait. Le modèle était faux, pas le code.
 *
 * On regarde maintenant une seule chose : y a-t-il des maisons autour du
 * joueur ? Si oui, on peuple. Ça marche sur n'importe quelle carte,
 * nommée ou non, y compris un hameau sans nom. Les localisations ne
 * décident plus OÙ l'on peuple, seulement COMBIEN.
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
 * Le réglage CBA « Population civile » décoché arrête tout : c'est un
 * coupe-circuit d'administrateur, pas un paramètre de mission.
 */

if (!isServer) exitWith {};

params [
    ["_densite",       -1],
    ["_habitants",     -1],
    ["_peupler",       true],
    ["_rayonAmbiance", 500],
    ["_portee",        -1],
    ["_distanceOubli", 1200],
    ["_distanceMin",   -1]
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

// ═══════════════════════════════════════════════════════════
// LES VALEURS DU SCÉNARIO
// ═══════════════════════════════════════════════════════════
// On relève la position des curseurs CBA pour deux raisons : servir de
// valeur quand le scénario dit -1, et repérer ensuite un mouvement.
private _cbaDensite = missionNamespace getVariable ["hds_civils_densite", 8];
private _cbaPortee  = missionNamespace getVariable ["hds_civils_portee", 500];

hds_vie_densite = if (_densite < 0) then { _cbaDensite } else { _densite };
hds_vie_portee  = if (_portee  < 0) then { _cbaPortee  } else { _portee  };

// Habitants : soit un nombre voulu par le scénario, soit la moitié du
// trafic. Dans le second cas seulement, ils suivront le curseur si
// quelqu'un le bouge en jeu — sinon le choix du scénario tient.
private _habitantsAuto = _habitants < 0;
hds_vie_habitants = if (_habitantsAuto) then {
    round (hds_vie_densite / 2)
} else {
    _habitants
};

// ── Le plafond du trafic ──
// Engima refuse un emplacement à moins de 100 m d'un autre véhicule,
// dans l'anneau portée×0,6 → portée. Sur une carte comme Stratis, il n'y
// a pas assez de bitume dans cet anneau pour y caser vingt voitures
// espacées de 100 m : passé un certain nombre, ses dix tentatives
// échouent toutes et il ne pose plus rien. Demander 24 véhicules
// revenait à en obtenir moins qu'en demandant 8.
//
// Ce plafond borne donc le FACTEUR DE LIEU, pas le choix du scénario :
// une mission qui demande 30 véhicules en aura jusqu'à 30, mais une
// mission qui en demande 8 ne montera pas au-delà de 14 parce qu'un
// joueur est entré en ville.
hds_vie_plafond = (round hds_vie_densite) max 14;

// ════════════════════════════════════════════════════════
// NE RIEN FAIRE APPARAÎTRE SOUS LE NEZ DU JOUEUR
// ════════════════════════════════════════════════════════
// Les habitants et les voitures garées naissaient dans un DISQUE
// centré sur le joueur, de 0 au rayon d'ambiance : donc jusqu'à ses
// pieds. On les voyait apparaître.
//
// La circulation d'Engima, elle, ne pope pas — parce qu'elle naît
// dans un ANNEAU, entre portée×0,6 et portée. C'est cette logique
// qu'on reprend ici, pour tout le reste de la vie civile.
//
// Le rayon d'ambiance par défaut passe donc de 300 à 500 m : un
// anneau a besoin de place. À 300 m, la zone interdite mangeait
// presque toute la zone de peuplement.
hds_vie_distance_min = if (_distanceMin < 0) then {
    _rayonAmbiance * 0.5
} else {
    _distanceMin
};
if (hds_vie_distance_min > (_rayonAmbiance * 0.85)) then {
    hds_vie_distance_min = _rayonAmbiance * 0.85;
};

["INFO", "CIVILS", format [
    "reglages retenus : trafic %1, habitants %2, portee %3 m, ambiance %4 m, apparition a %5 m mini, oubli %6 m (source : %7)",
    hds_vie_densite, hds_vie_habitants, hds_vie_portee, _rayonAmbiance,
    round hds_vie_distance_min, _distanceOubli,
    (["scenario", "menu CBA"] select (_densite < 0))
]] call hds_fnc_log;

// ═══════════════════════════════════════════════════════════
// LE TRAFIC : ON PASSE LA MAIN
// ═══════════════════════════════════════════════════════════
// Après avoir posé hds_vie_* : ConfigAndStart.sqf les lit au démarrage.
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

// ─── Le facteur du lieu ───
// Un périmètre qui englobe une ville ou un village doit être plus animé
// qu'un bout de route en rase campagne — plus de circulation ET plus
// d'habitants. Les localisations déclarées par la carte ne décident donc
// plus OÙ l'on peuple, mais COMBIEN.
//
// C'est la bonne façon de s'en servir : quand elles manquent, comme au
// sud de Stratis, on peuple quand même, simplement à la densité de base.
private _fnFacteur = {
    params ["_pos"];

    private _f = 1;

    if !((nearestLocations [_pos, ["NameCityCapital", "NameCity"], 600]) isEqualTo []) then {
        _f = 3;
    } else {
        if !((nearestLocations [_pos, ["NameVillage", "NameLocal"], 450]) isEqualTo []) then {
            _f = 1.8;
        };
    };

    _f
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

    // ─── La télécommande CBA ───
    // On ne lit pas le curseur, on surveille s'il a BOUGÉ. Tant qu'il ne
    // bouge pas, la valeur du scénario tient — y compris après les
    // rafraîchissements que CBA déclenche tout seul.
    private _curDensite = missionNamespace getVariable ["hds_civils_densite", _cbaDensite];
    if (_curDensite != _cbaDensite) then {
        _cbaDensite = _curDensite;
        hds_vie_densite = _curDensite;
        hds_vie_plafond = (round _curDensite) max 14;
        if (_habitantsAuto) then { hds_vie_habitants = round (_curDensite / 2) };

        ["INFO", "CIVILS", format [
            "densite changee en jeu : %1 vehicule(s), %2 habitant(s)",
            _curDensite, hds_vie_habitants
        ]] call hds_fnc_log;
    };

    private _curPortee = missionNamespace getVariable ["hds_civils_portee", _cbaPortee];
    if (_curPortee != _cbaPortee) then {
        _cbaPortee = _curPortee;
        hds_vie_portee = _curPortee;

        ["INFO", "CIVILS", format ["portee changee en jeu : %1 m", _curPortee]]
            call hds_fnc_log;
    };

    private _actif   = missionNamespace getVariable ["hds_civils_actifs", true];
    private _voulu   = round hds_vie_densite;
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

        // ─── LA CIRCULATION SUIT LE LIEU ───
        // On prend le facteur le plus élevé parmi les joueurs : si l'un
        // d'eux est en ville, la circulation monte. Engima relit ce
        // nombre à chaque tour de sa propre boucle.
        private _facteurMax = 1;
        {
            private _f = [getPosATL _x] call _fnFacteur;
            if (_f > _facteurMax) then { _facteurMax = _f };
        } forEach _joueurs;

        // Facteur adouci : en ville, +70 % et non +200 %. Le plafond,
        // lui, ne borne que ce supplément — voir plus haut.
        private _facteurDoux  = 1 + ((_facteurMax - 1) * 0.35);
        private _compteTrafic = ((round (_voulu * _facteurDoux)) max 0) min hds_vie_plafond;

        if (_compteTrafic != (missionNamespace getVariable ["hds_engima_count", -1])) then {
            hds_engima_count = _compteTrafic;

            ["INFO", "CIVILS", format [
                "circulation : %1 vehicule(s) vises (densite %2 x facteur lieu %3)",
                _compteTrafic, _voulu, _facteurMax
            ]] call hds_fnc_log;
        };

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

                            // Le facteur du lieu joue aussi sur les
                            // habitants : une ville est plus peuplée
                            // qu'un hameau, à densité demandée égale.
                            private _plus = round (hds_vie_habitants * ([_p] call _fnFacteur));

                            [_p, _plus, _rayonAmbiance, _idCiv, false, hds_vie_distance_min]
                                spawn fnc_occupations_civil_init;

                            [_p, _rayonAmbiance, -1, _idCiv, hds_vie_distance_min]
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
