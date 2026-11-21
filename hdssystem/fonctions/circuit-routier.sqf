/*
 * hds_fnc_circuitRoutier
 * ─────────────────────────────────────────────────────────────
 * Fait tourner un groupe embarqué sur les routes d'une zone, en
 * boucle, au lieu de le laisser traverser les bois.
 *
 *  0 : <GROUP>  le groupe à faire patrouiller
 *  1 : <ARRAY>  centre de la zone
 *  2 : <NUMBER> rayon de la zone (m)
 *  3 : <NUMBER> nombre d'étapes du circuit (facultatif, défaut 5)
 *
 * Retourne <BOOL> : vrai si un circuit routier a été posé, faux si la
 * zone n'a pas assez de route pour en faire un — à l'appelant de se
 * rabattre sur BIS_fnc_taskPatrol dans ce cas.
 *
 * ── Pourquoi pas BIS_fnc_taskPatrol ──
 * Elle tire des points au hasard dans un cercle et pose des MOVE
 * dessus. Pour de l'infanterie c'est très bien. Pour un véhicule, un
 * point sur deux tombe dans un champ ou un bois, et le camion y va :
 * c'est le chemin le plus court vers le point demandé.
 *
 * ── Comment les points sont choisis ──
 * Tirer cinq routes au hasard ne suffit pas : elles peuvent tomber sur
 * le même tronçon, et le véhicule fait des allers-retours de cinquante
 * mètres. On découpe donc le cercle en autant de secteurs que
 * d'étapes, on prend une route dans chacun, et on préfère celles qui
 * sont loin du centre. Le circuit fait alors le tour de la zone.
 *
 * ── forceFollowRoad ──
 * Les waypoints sur route ne garantissent rien entre deux points : le
 * moteur coupe au plus court s'il y trouve son compte. forceFollowRoad
 * l'en empêche. Deux précautions avec lui :
 *
 *   - on ne l'applique qu'à un véhicule déjà sur route, sinon on peut
 *     coincer sur place celui qui a apparu dans un champ ;
 *   - il est relâché au premier contact. Une fois alertés, ils font ce
 *     qu'ils veulent — c'est le but d'une patrouille qui réagit.
 *
 * Et relâché aussi si le véhicule reste planté, au cas où. L'immobilité
 * n'est comptée que si la simulation tourne vraiment : avec
 * enableDynamicSimulation, un groupe loin des joueurs est à l'arrêt
 * sans être bloqué pour autant.
 */

params [
    ["_groupe", grpNull, [grpNull]],
    ["_centre", [0, 0, 0], [[]]],
    ["_rayon",  500, [0]],
    ["_etapes", 5, [0]]
];

if (isNull _groupe) exitWith { false };
if (count _centre < 2) exitWith { false };

_etapes = (round _etapes) max 3 min 8;

// ─── Les routes de la zone ───
// nearRoads coûte cher : un seul appel, tout le reste travaille sur
// le résultat.
private _routes = _centre nearRoads _rayon;

if (count _routes < 3) exitWith {
    ["INFO", "OCCUPATIONS", format [
        "pas de circuit routier : %1 troncon(s) dans %2 m",
        count _routes, _rayon
    ]] call hds_fnc_log;
    false
};

// ─── Répartir les tronçons par secteur angulaire ───
private _secteurs = [];
for "_i" from 1 to _etapes do { _secteurs pushBack [] };

private _cx = _centre select 0;
private _cy = _centre select 1;
private _pas = 360 / _etapes;

{
    private _p  = getPos _x;
    private _dx = (_p select 0) - _cx;
    private _dy = (_p select 1) - _cy;

    // atan2 rend -180..180 ; on ramène sur 0..360
    private _angle = ((_dx atan2 _dy) + 360) % 360;
    private _index = (floor (_angle / _pas)) min (_etapes - 1);

    (_secteurs select _index) pushBack [_p, _p distance2D _centre];
} forEach _routes;

// ─── Une étape par secteur, la plus excentrée ───
// Un secteur sans route est simplement sauté : mieux vaut un circuit
// à quatre côtés qu'un détour par un bois pour respecter la forme.
private _points = [];

{
    private _candidats = _x;

    if !(_candidats isEqualTo []) then {
        // Les tronçons au-delà de 45 % du rayon d'abord ; faute de
        // quoi, le plus éloigné de ce secteur.
        private _loin = _candidats select { (_x select 1) >= (_rayon * 0.45) };

        private _choisi = if (_loin isEqualTo []) then {
            private _meilleur = _candidats select 0;
            { if ((_x select 1) > (_meilleur select 1)) then { _meilleur = _x } } forEach _candidats;
            _meilleur
        } else {
            selectRandom _loin
        };

        _points pushBack (_choisi select 0);
    };
} forEach _secteurs;

if (count _points < 2) exitWith {
    ["INFO", "OCCUPATIONS",
     "pas de circuit routier : routes trop groupees pour faire une boucle"
    ] call hds_fnc_log;
    false
};

// ─── Poser le circuit ───
// On efface d'abord ce que le groupe avait : un reste de waypoint
// ailleurs enverrait le véhicule hors zone avant de commencer.
while { (count (waypoints _groupe)) > 0 } do {
    deleteWaypoint ((waypoints _groupe) select 0);
};

{
    private _wp = _groupe addWaypoint [_x, 0];
    _wp setWaypointType             "MOVE";
    _wp setWaypointBehaviour        "SAFE";
    _wp setWaypointSpeed            "LIMITED";
    _wp setWaypointCombatMode       "YELLOW";
    _wp setWaypointFormation        "COLUMN";
    _wp setWaypointCompletionRadius 20;
} forEach _points;

private _cycle = _groupe addWaypoint [_points select 0, 0];
_cycle setWaypointType             "CYCLE";
_cycle setWaypointCompletionRadius 20;

// ─── Coller à la route ───
private _contraints = [];

{
    private _v = vehicle _x;

    if (!(_v isEqualTo _x) && { isOnRoad (getPosATL _v) } && { !(_v in _contraints) }) then {
        _v forceFollowRoad true;
        _contraints pushBack _v;
    };
} forEach (units _groupe);

// ─── Relâcher au premier contact ───
if !(_contraints isEqualTo []) then {
    [_groupe, _contraints] spawn {
        params ["_grp", "_vehs"];

        private _immobile = 0;

        while { !isNull _grp && { !((units _grp) isEqualTo []) } } do {

            private _chef = leader _grp;
            private _veh  = vehicle _chef;

            if (isNull _chef || { !alive _chef }) exitWith {};

            private _libere = (behaviour _chef) isEqualTo "COMBAT";

            // Planté ? Mais seulement si la simulation tourne : un
            // groupe mis en veille par la simulation dynamique est à
            // l'arrêt sans être bloqué.
            if (simulationEnabled _veh && { (speed _veh) < 1 }) then {
                _immobile = _immobile + 1;
                if (_immobile >= 6) then { _libere = true };
            } else {
                _immobile = 0;
            };

            if (_libere) exitWith {
                { if (!isNull _x) then { _x forceFollowRoad false } } forEach _vehs;
            };

            sleep 5;
        };
    };
};

["INFO", "OCCUPATIONS", format [
    "circuit routier : %1 etapes sur %2 troncons, %3 vehicule(s) tenus sur route",
    count _points, count _routes, count _contraints
]] call hds_fnc_log;

true
