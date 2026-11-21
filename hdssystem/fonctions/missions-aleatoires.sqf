/*
 * fnc_hds_missions
 * ─────────────────────────────────────────────────────────────
 * Enchaîne des missions aléatoires : pour chacune, une occupation
 * ennemie sur une localisation tirée au sort, de la planification
 * tactique autour, éventuellement des civils, et une ou plusieurs
 * tâches. Quand les tâches sont faites, pause, nettoyage du secteur,
 * et on recommence.
 *
 * 0 : <NUMBER>             rayon d'action de la mission (m)
 * 1 : <NUMBER|STRING|SIDE> faction ennemie — passe par le registre,
 *                          donc 0..7, un id ("rhs_faction_vdv") ou
 *                          east / "AUTO"
 * 2 : <NUMBER>             nombre de missions à enchaîner
 * 3 : <NUMBER>             difficulté : densité des occupations
 * 4 : <ARRAY>              types de localisation où chercher un lieu
 * 5 : <BOOL>               population civile sur place ?
 * 6 : <BOOL>              faction tirée au sort ? (ignore le 1)
 * 7 : <NUMBER>             nombre de tâches par mission
 *
 * À lancer avec spawn :
 *   [700, 0, 2, 1, ["NameCity","NameLocal","NameVillage"], true, false, 3]
 *     spawn fnc_hds_missions;
 *
 * ─────────────────────────────────────────────────────────────
 * ── Ce qui a été réparé en la câblant ──
 *
 * Le corps de cette fonction existait depuis le début dans
 * hdssystem\fonctions\fonctions\ops-missions.sqf, mais n'était assigné
 * à aucun nom : un corps sans étiquette. Le générateur web, lui,
 * savait déjà émettre « spawn fnc_hds_missions ». Choisir cette étape
 * produisait donc une variable indéfinie, et comme en SQF cela AVORTE
 * le script, toutes les étapes suivantes du scénario tombaient avec
 * elle.
 *
 * En l'assignant, trois défauts sont apparus, qu'il fallait corriger
 * sous peine de livrer un piège :
 *
 *   1. Boucle infinie. « while {nombre_de_missions > 0} » ne
 *      décrémentait jamais rien. La ligne 30 lisait le compteur dans
 *      une variable locale aussitôt oubliée — visiblement l'endroit
 *      où le décompte devait se trouver. Il y est maintenant.
 *      (Le seul « nombre_de_missions - 1 » du dépôt est dans une
 *      branche d'échec de objectif_infos.sqf : ce n'était pas le
 *      compteur de boucle.)
 *
 *   2. Le nettoyage supprimait les joueurs. « deleteVehicle » était
 *      appliqué à tous les "Man" du rayon, sans distinction. Un joueur
 *      encore sur place après la mission y passait, et les renforts
 *      alliés qu'il avait appelés aussi. On protège désormais les
 *      joueurs, les groupes qui en contiennent un, et tout le camp
 *      des joueurs.
 *
 *   3. Attente sans issue. « waitUntil {tache_effectuee isEqualTo n} »
 *      exigeait l'égalité stricte : une tâche qui s'incrémente deux
 *      fois (plusieurs objectif_* le font sur leur chemin d'échec) et
 *      le compteur sautait par-dessus la valeur attendue, pour ne plus
 *      jamais y revenir. C'est un >= , et il y a une limite de temps.
 */

if (!isServer) exitWith {};

params [
    ["_rayon",            700],
    ["_faction",          east],
    ["_nbMissions",       1],
    ["_difficulte",       1],
    ["_typeLocalisation", ["NameCity", "NameLocal", "NameVillage"]],
    ["_civils",           true],
    ["_factionAleatoire", false],
    ["_nbTaches",         1]
];

if (!canSuspend) exitWith {
    ["ERREUR", "MISSIONS", "fnc_hds_missions doit etre lancee avec spawn, pas call"] call hds_fnc_log;
};

// ─── Compteurs partagés ───
// pointdevehicule est normalement posé par fnc_scenario_init, que le
// générateur émet toujours dans le bloc « Contexte ». Mais une mission
// écrite à la main peut appeler cette fonction sans lui : on ne veut
// pas d'un « pointdevehicule = pointdevehicule + 3 » sur une variable
// qui n'existe pas, ce qui avorterait tout.
if (isNil "pointdevehicule") then { pointdevehicule = 0; publicVariable "pointdevehicule"; };
if (isNil "tache_effectuee") then { tache_effectuee = 0; publicVariable "tache_effectuee"; };

// ─── Lieux candidats ───
// Centre de la carte et rayon worldSize : couvre n'importe quelle
// carte, au lieu du coin [0,0,0] et des 40 km codés en dur.
private _localisations = nearestLocations [
    [worldSize / 2, worldSize / 2, 0],
    _typeLocalisation,
    worldSize
];

if (_localisations isEqualTo []) exitWith {
    ["ALERTE", "MISSIONS", format [
        "aucune localisation de type %1 sur %2 - aucune mission generee",
        _typeLocalisation, worldName
    ]] call hds_fnc_log;
};

nombre_de_missions = _nbMissions;
publicVariable "nombre_de_missions";

["INFO", "MISSIONS", format [
    "%1 mission(s) a enchainer, %2 tache(s) chacune, rayon %3 m, %4 lieu(x) candidat(s)",
    _nbMissions, _nbTaches, _rayon, count _localisations
]] call hds_fnc_log;

while { nombre_de_missions > 0 } do {

    tache_effectuee = 0;
    publicVariable "tache_effectuee";

    // Les marqueurs présents AVANT la mission sont ceux de l'éditeur et
    // de la base : le nettoyage ne doit pas y toucher. On ne supprimera
    // que ceux apparus pendant.
    private _marqueursAvant = allMapMarkers;

    private _lieu = locationPosition (selectRandom _localisations);

    waitUntil { count allPlayers > 0 };
    sleep 10;

    // ─── Faction ───
    // HFactionennemi tient les anciens index ; hds_fnc_factionResoudre
    // les accepte comme il accepte un id du registre. Rien à traduire
    // ici.
    private _ennemi = _faction;
    if (_factionAleatoire) then { _ennemi = selectRandom HFactionennemi; };

    ["INFO", "MISSIONS", format [
        "mission sur [%1,%2] - faction %3 - %4 restante(s)",
        round (_lieu select 0), round (_lieu select 1), _ennemi, nombre_de_missions
    ]] call hds_fnc_log;

    // ─── Occupation et planification ───
    [_lieu, _difficulte, _ennemi, _rayon, false] spawn fnc_hds_occupations;
    [_lieu, _rayon * 2, _ennemi, 1, _difficulte + 1] spawn fnc_tactique_plannification;

    // ─── Civils ───
    // L'ancienne version traduisait l'index de faction en « nationalité »
    // 0 à 3. Ces listes de classnames ont été retirées avec le reste des
    // factions codées en dur : le registre choisit désormais une faction
    // civile du serveur. On passe donc "" et on le laisse faire.
    // hds_civils_actifs est le réglage CBA « Population civile ».
    if (_civils && { missionNamespace getVariable ["hds_civils_actifs", true] }) then {
        [_lieu, 0, _rayon, "", false] spawn fnc_occupations_civil_init;
    };

    if (boutiqueactive) then {
        comptedemissions = (_rayon / 3) * _difficulte;
    };

    // ─── Tâches ───
    for "_i" from 1 to _nbTaches do {
        sleep 5;
        [_lieu, _rayon / 1.5, _ennemi] spawn fnc_objectif_aleatoire;
    };

    // ─── Simulation dynamique sur ce qui vient d'être posé ───
    {
        (group _x) enableDynamicSimulation true;
    } forEach (allUnits inAreaArray [_lieu, _rayon, _rayon, 0, false, 100]);
    {
        _x enableDynamicSimulation true;
    } forEach (vehicles inAreaArray [_lieu, _rayon, _rayon, 0, false, 100]);

    // ─── Attendre que les tâches soient faites ───
    // Limite de temps : si une tâche ne s'achève jamais — objectif
    // cassé, objet détruit avant d'être atteint — la chaîne de missions
    // doit continuer au lieu de rester bloquée là pour la partie.
    //
    // Pas de sleep dans la condition : le code d'un waitUntil ne peut
    // pas se suspendre. Deux comparaisons par image, c'est négligeable.
    private _limite = time + 7200;
    waitUntil { tache_effectuee >= _nbTaches || { time > _limite } };

    if (tache_effectuee < _nbTaches) then {
        ["ALERTE", "MISSIONS", format [
            "limite de temps atteinte avec %1/%2 tache(s) - on passe a la suite",
            tache_effectuee, _nbTaches
        ]] call hds_fnc_log;
    } else {
        ["INFO", "MISSIONS", "mission terminee"] call hds_fnc_log;
    };

    // ─── Récompense ───
    pointdevehicule = pointdevehicule + _nbTaches;
    publicVariable "pointdevehicule";
    [format ["%1 : %2 point(s) de véhicule ajouté(s)", hdsversion, _nbTaches]]
        remoteExecCall ["systemChat", 0];

    // ─── Décompte ───
    // C'est la ligne qui manquait. Sans elle, la boucle ne finissait
    // jamais, quel que soit le nombre de missions demandé.
    nombre_de_missions = nombre_de_missions - 1;
    publicVariable "nombre_de_missions";

    // ─── Pause avant la suivante ───
    if (nombre_de_missions > 0) then {
        private _attente = 200 + round (random 400);
        ["INFO", "MISSIONS", format ["pause de %1 s avant la mission suivante", _attente]]
            call hds_fnc_log;
        sleep _attente;
    };

    // ─── Nettoyage du secteur ───
    // Ce qui est protégé : un joueur, un homme d'un groupe où il y a un
    // joueur, et tout le camp des joueurs — les renforts alliés en
    // font partie. Un véhicule vide n'est pas touché non plus : rien ne
    // dit s'il appartient à la mission ou à un joueur, et supprimer
    // l'hélico de quelqu'un coûte plus cher que laisser une épave.
    private _campJoueurs = west;
    if (count allPlayers > 0) then {
        _campJoueurs = side (group (allPlayers select 0));
    };

    private _supprimes = 0;
    {
        private _o = _x;
        private _gens = if (_o isKindOf "Man") then { [_o] } else { crew _o };

        if !(_gens isEqualTo []) then {
            private _garder = (_gens findIf {
                isPlayer _x
                || { side (group _x) isEqualTo _campJoueurs }
                || { ((units (group _x)) findIf { isPlayer _x }) >= 0 }
            }) >= 0;

            if (!_garder) then {
                { deleteVehicle _x } forEach _gens;
                if !(_o isKindOf "Man") then { deleteVehicle _o };
                _supprimes = _supprimes + 1;
            };
        };
    } forEach (nearestObjects [
        _lieu,
        ["Man", "Car", "Tank", "Helicopter", "Plane", "Ship"],
        _rayon
    ]);

    {
        if (!(_x in _marqueursAvant) && { (getMarkerPos _x) distance _lieu < _rayon }) then {
            deleteMarker _x;
        };
    } forEach allMapMarkers;

    ["INFO", "MISSIONS", format ["secteur nettoye - %1 element(s) retire(s)", _supprimes]]
        call hds_fnc_log;
};

["INFO", "MISSIONS", "chaine de missions terminee"] call hds_fnc_log;

true

/* Types de localisation acceptés en paramètre 4
 *   "NameVillage"  village
 *   "NameCity"     ville
 *   "Name"         endroit commun
 *   "NameLocal"    endroit particulier
 *   "Strategic"    base militaire
 */
