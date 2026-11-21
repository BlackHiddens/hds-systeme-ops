/*
 * fnc_occupations_init
 * ─────────────────────────────────────────────────────────────
 * Moteur de mise en place d'une occupation dans une zone.
 * Appelé par fnc_hds_occupations, qui lui fournit les compositions
 * issues du registre de factions.
 *
 *  0 : <ARRAY>   position du centre
 *  1 : <NUMBER>  rayon du secteur (m)
 *  2 : <NUMBER>  nombre d'équipes à générer
 *  3 : <CONFIG|ARRAY> compositions à employer :
 *        CONFIG            une entrée CfgGroups — ancien appel, conservé
 *        ARRAY de CONFIG   tirage au sort à chaque équipe (varie les
 *                          compositions dans une même zone)
 *        ARRAY de STRING   classnames de véhicules (type 2)
 *  4 : <NUMBER>  type : 0 garnison / 1 patrouille / 2 véhicules
 *  5 : <SIDE>    camp
 *  6 : <BOOL>    marqueur visible sur la carte (facultatif, défaut false)
 *
 * Exemple (ancien appel, toujours valide) :
 *   [_pos, 500, 2, (configFile >> "CfgGroups" >> "East" >> "OPF_F"
 *                   >> "Infantry" >> "OIA_InfSquad"), 0, east]
 *     call fnc_occupations_init;
 *
 * Exemple (registre) :
 *   [_pos, 500, 2, ([east,"GARNISON"] call hds_fnc_factionGroupes), 0, east, false]
 *     call fnc_occupations_init;
 */

params [
    ["_position",        [0,0,0]],
    ["_taille",          500],
    ["_nombres_equipes", 1],
    ["_compositions",    configNull],
    ["_type_occupation", 0],
    ["_camps",           east],
    ["_visible",         false]
];

// ─── Tire une composition : accepte une entrée seule ou un tableau ───
private _fnTirage = {
    params ["_src"];
    if (_src isEqualType []) then {
        if (_src isEqualTo []) then { configNull } else { selectRandom _src }
    } else {
        _src
    };
};

// ─── Marqueur de secteur ───
// Compteur et non nombre au hasard : avec plusieurs occupations, deux
// zones finissaient par partager le même nom de marqueur.
if (isNil "hds_occups_compteur") then { hds_occups_compteur = 0 };
hds_occups_compteur = hds_occups_compteur + 1;

private _secteur = [
    format ["hds_occups_%1", hds_occups_compteur],
    _position,
    "Ellipse",
    [_taille, _taille],
    "BRUSH:",  "SolidBorder",
    "COLOR:",  "colorOPFOR"
] call cba_fnc_createMarker;

_secteur setMarkerAlpha 0;
// La mission peut demander ce marqueur pour elle-même : dans ce
// cas son alpha normal est 1 et le mode debug n'y change rien.
// Sinon c'est le debug seul qui le montre, et le décocher le fait
// disparaître dans la seconde.
[_secteur, ([0, 1] select (_visible isEqualTo true))] call hds_fnc_debugMarqueur;

// ═══════════════════════════════════════════════════════════
// TROUPES AU SOL — garnison (0) et patrouille (1)
// ═══════════════════════════════════════════════════════════
if (_type_occupation in [0, 1]) then {

    for "_i" from 1 to _nombres_equipes do {

        private _cfg = [_compositions] call _fnTirage;

        if (isNull _cfg) then {
            diag_log "[HDS][OCCUPATIONS] Aucune composition disponible — equipe ignoree";
        } else {

            private _equipe = [
                (_secteur call BIS_fnc_randomPosTrigger),
                _camps,
                _cfg
            ] call BIS_fnc_spawnGroup;

            private _postes = 0;

            if (_type_occupation isEqualTo 0) then {
                // hds_fnc_garnison place ET anime, dans cet ordre.
                // Surtout ne pas réanimer ici : c'est précisément ce qui
                // figeait les hommes dehors, avant qu'ils n'entrent.
                _postes = [_position, nil, (units _equipe), _taille, 1, false, true] call hds_fnc_garnison;
            } else {
                [_equipe, (getMarkerPos _secteur), _taille] call BIS_fnc_taskPatrol;
            };

            _equipe enableDynamicSimulation true;

            if (hdssysteme) then {
                private _quoi = ["patrouille", "garnison"] select (_type_occupation isEqualTo 0);
                diag_log format [
                    "[HDS][OCCUPATIONS] %1 : equipe de %2 - %3 (%4 h%5)",
                    hdsversion, _quoi, configName _cfg, count (units _equipe),
                    (["", format [", %1 postes en batiment", _postes]] select (_type_occupation isEqualTo 0))
                ];
                [format ["%1 : création d'une équipe de %2", hdsversion, _quoi]]
                    remoteExecCall ["systemChat", 0];
            };
        };
    };
};

// ═══════════════════════════════════════════════════════════
// VÉHICULES (2)
// ═══════════════════════════════════════════════════════════
if (_type_occupation isEqualTo 2) then {

    private _classes = if (_compositions isEqualType []) then { _compositions } else { [] };

    if (_classes isEqualTo []) then {
        diag_log "[HDS][OCCUPATIONS] Aucun vehicule fourni — occupation vehicules ignoree";
    } else {

        for "_i" from 1 to (_nombres_equipes - 1) do {

            // Départ sur une route si on en trouve une, sinon dans la zone
            private _routes = _position nearRoads (_taille * 2);
            private _depart = if (_routes isEqualTo []) then {
                _secteur call BIS_fnc_randomPosTrigger
            } else {
                getPos (selectRandom _routes)
            };

            private _cls = selectRandom _classes;
            private _vehicule = [_depart, 180, _cls, _camps] call BIS_fnc_spawnVehicle;
            private _equipe = _vehicule select 2;

            // Un véhicule n'a rien à faire dans un bois : on lui trace
            // un circuit sur les routes de la zone. Repli sur la
            // patrouille libre là où il n'y a pas de route du tout,
            // un véhicule à l'arrêt étant pire qu'un véhicule en forêt.
            private _surRoute = [_equipe, _position, _taille] call hds_fnc_circuitRoutier;

            if (!_surRoute) then {
                [_equipe, (_secteur call BIS_fnc_randomPosTrigger), _taille] call BIS_fnc_taskPatrol;
            };
            _equipe enableDynamicSimulation true;

            if (hdssysteme) then {
                diag_log format [
                    "[HDS][OCCUPATIONS] %1 : equipe embarquee — %2",
                    hdsversion, _cls
                ];
                [format ["%1 : création d'une équipe embarquée", hdsversion]]
                    remoteExecCall ["systemChat", 0];
            };
        };
    };
};

true
