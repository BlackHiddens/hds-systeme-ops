/*
 * hdssystem\debug-carte.sqf
 * ─────────────────────────────────────────────────────────────
 * Debug carte — marqueurs locaux d'ennemis, visibles du seul joueur
 * qui exécute ce script. Appelé côté CLIENT depuis initplayerlocal.sqf.
 *
 * Suit hdssysteme, qui vaut « AUTO » par défaut : allumé quand tu
 * héberges la mission toi-même, éteint sur un serveur dédié.
 * Voir mes-parametres.sqf.
 *
 * ── Pourquoi le test est dans la boucle et pas en sortie immédiate ──
 * Le script sortait sur « if (!hdssysteme) exitWith {} » dès le
 * chargement. Le réglage CBA « Mode debug » pouvait donc être coché en
 * cours de partie sans que les marqueurs n'apparaissent jamais : le
 * script n'existait plus.
 *
 * ── Pourquoi deux rythmes ──
 * Redessiner des marqueurs pour chaque ennemi de la carte coûte cher :
 * ça reste donc à trente secondes. Mais relire un booléen ne coûte
 * rien, et décocher la case doit se voir tout de suite. On sépare donc
 * les deux : un battement d'une demi-seconde qui ne fait que comparer
 * l'état, et le dessin complet toutes les trente secondes.
 *
 * Le passage de allumé à éteint efface les marqueurs dans la foulée ;
 * le passage inverse redessine sans attendre le cycle suivant.
 *
 * ── Ce qui est dessiné ──
 *   - un triangle par groupe ennemi, avec son nom et son effectif,
 *     et un point par homme vivant ;
 *   - l'itinéraire de chaque groupe d'IA : une polyligne qui relie
 *     ses waypoints dans l'ordre, les étapes numérotées, celle en
 *     cours en jaune. Rouge pour l'OPFOR, vert pour les indépendants,
 *     bleu pour le BLUFOR, orange pour les civils.
 *
 * L'itinéraire sert surtout à vérifier d'un coup d'œil que les
 * circuits de véhicules passent bien par les routes — voir
 * hdssystem\fonctions\circuit-routier.sqf. Un groupe qui part en
 * COMBAT abandonne ses waypoints : sa polyligne disparaît toute
 * seule au cycle suivant, ce qui se lit très bien.
 *
 * Les marqueurs d'alpha posés par les objectifs et les occupations,
 * eux, sont gérés par hdssystem\debug-mode.sqf.
 */

[] spawn {
    sleep 8; // Laisser le temps aux groupes OPFOR d'être créés

    private _mkrs = [];
    private _dernierEtat  = false;
    private _prochainTour = 0;

    while {true} do {

        private _actif = hdssysteme isEqualTo true;

        // ─── La case vient de changer ───
        if !(_actif isEqualTo _dernierEtat) then {
            { deleteMarkerLocal _x } forEach _mkrs;
            _mkrs = [];
            _prochainTour = 0; // si on vient d'allumer : dessiner maintenant
            _dernierEtat  = _actif;
        };

        // ─── Dessin complet, au plus toutes les 30 s ───
        if (_actif && { time >= _prochainTour }) then {

            { deleteMarkerLocal _x } forEach _mkrs;
            _mkrs = [];

            private _groupesEnnemis = allGroups select { side _x in [east, independent] };
            private _i = 0;

            {
                private _groupe  = _x;
                private _vivants = units _groupe select { alive _x };

                if (count _vivants == 0) then { _i = _i + 1; continue; };

                private _leader = leader _groupe;
                if (isNull _leader) then { _i = _i + 1; continue; };

                private _pos = getPosATL _leader;
                private _gid = groupId _groupe;
                private _nb  = count _vivants;

                // Triangle chef de groupe (LOCAL — ce joueur seulement)
                private _mGrp = createMarkerLocal [format ["hds_cl_g%1", _i], _pos];
                _mGrp setMarkerShapeLocal "ICON";
                _mGrp setMarkerTypeLocal  "mil_triangle";
                _mGrp setMarkerColorLocal "ColorRed";
                _mGrp setMarkerTextLocal  format ["%1 (%2u)", _gid, _nb];
                _mGrp setMarkerSizeLocal  [1.5, 1.5];
                _mGrp setMarkerAlphaLocal 1;
                _mkrs pushBack _mGrp;

                // Points individuels
                {
                    private _pu = createMarkerLocal [format ["hds_cl_u%1_%2", _i, _forEachIndex], getPosATL _x];
                    _pu setMarkerShapeLocal "ICON";
                    _pu setMarkerTypeLocal  "mil_dot";
                    _pu setMarkerColorLocal "ColorRed";
                    _pu setMarkerSizeLocal  [0.55, 0.55];
                    _pu setMarkerAlphaLocal 0.9;
                    _mkrs pushBack _pu;
                } forEach _vivants;

                _i = _i + 1;

            } forEach _groupesEnnemis;

            // ═══════════════════════════════════════════════
            // ITINÉRAIRES
            // ═══════════════════════════════════════════════
            // Un marqueur POLYLINE par groupe, pas un par segment :
            // une polyligne EST un itinéraire, c'est exactement ce
            // qu'il faut. Sert surtout à vérifier d'un coup d'œil que
            // les circuits de véhicules suivent bien les routes.
            //
            // Tous les camps, sauf les groupes où il y a un joueur :
            // l'itinéraire d'un groupe de joueurs n'existe pas, et on
            // ne va pas afficher le sien sur sa propre carte.

            private _groupesIA = allGroups select {
                !((units _x) isEqualTo [])
                && { ((units _x) findIf { isPlayer _x }) < 0 }
                && { (count (waypoints _x)) > 1 }
            };

            // Garde-fou : sur une carte très peuplée, mieux vaut un
            // dessin incomplet qu'un millier de marqueurs locaux.
            if (count _groupesIA > 60) then {
                _groupesIA resize 60;
                diag_log "[HDS][DEBUG] itineraires : plus de 60 groupes, dessin limite";
            };

            private _j = 0;

            {
                private _grp    = _x;
                private _actuel = currentWaypoint _grp;

                private _plat = [];   // [x1, y1, x2, y2, ...] pour la polyligne
                private _pts  = [];   // [position, index d'origine] pour les étapes

                {
                    private _p = waypointPosition _x;

                    // Un waypoint accroché à un objet peut rendre
                    // [0,0,0] : il n'a rien à faire sur la carte.
                    if (((_p select 0) > 0) || { (_p select 1) > 0 }) then {
                        _pts  pushBack [_p, _forEachIndex];
                        _plat pushBack (_p select 0);
                        _plat pushBack (_p select 1);
                    };
                } forEach (waypoints _grp);

                if (count _pts > 1) then {

                    private _couleur = switch (side _grp) do {
                        case east:        { "ColorRed" };
                        case independent: { "ColorGreen" };
                        case west:        { "ColorBlue" };
                        default           { "ColorOrange" };
                    };

                    private _ligne = createMarkerLocal [
                        format ["hds_cl_i%1", _j], ((_pts select 0) select 0)
                    ];
                    _ligne setMarkerShapeLocal    "POLYLINE";
                    _ligne setMarkerPolylineLocal _plat;
                    _ligne setMarkerColorLocal    _couleur;
                    _ligne setMarkerAlphaLocal    0.7;
                    _mkrs pushBack _ligne;

                    // Étapes numérotées, celle en cours en jaune :
                    // on voit où ils en sont dans leur boucle.
                    {
                        _x params ["_p", "_n"];

                        private _e = createMarkerLocal [
                            format ["hds_cl_e%1_%2", _j, _n], _p
                        ];
                        _e setMarkerShapeLocal "ICON";
                        _e setMarkerTypeLocal  "mil_dot";
                        _e setMarkerColorLocal (["ColorYellow", _couleur] select (_n != _actuel));
                        _e setMarkerSizeLocal  [0.5, 0.5];
                        _e setMarkerTextLocal  (format ["%1", _n]);
                        _e setMarkerAlphaLocal 0.8;
                        _mkrs pushBack _e;
                    } forEach _pts;
                };

                _j = _j + 1;

            } forEach _groupesIA;

            _prochainTour = time + 30;
        };

        sleep 0.5; // Relire l'état de la case, rien de plus
    };
};
