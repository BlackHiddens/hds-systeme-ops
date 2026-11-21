/*
 * hds_fnc_journalRapport
 * ─────────────────────────────────────────────────────────────
 * Construit un rapport texte prêt à être collé : un en-tête qui
 * décrit l'environnement, puis les lignes du tampon.
 *
 * 0 : <NUMBER> nombre de lignes à garder, les plus récentes
 *              (0 ou absent = tout le tampon)
 * 1 : <STRING> ne garder que ce niveau et plus grave
 *              ("" = tout ce que le tampon contient)
 *
 * Retourne : <STRING> le rapport
 *
 * L'en-tête compte autant que les lignes : il dit la carte, la
 * version du jeu, les mods détectés et l'état du registre de
 * factions. C'est ce qui évite les allers-retours de questions.
 *
 * Exemples :
 *   private _r = [] call hds_fnc_journalRapport;             // tout
 *   private _r = [50, "ALERTE"] call hds_fnc_journalRapport; // 50 dernieres, erreurs+alertes
 */

params [["_max", 0], ["_niveauMin", ""]];

private _l = +hds_journal;

// ─── Filtre de niveau ───
if (_niveauMin != "") then {
    private _iMin = hds_journal_niveaux findIf { _x isEqualTo (toUpper _niveauMin) };
    if (_iMin >= 0) then {
        private _gardes = hds_journal_niveaux select [0, _iMin + 1];
        _l = _l select {
            private _ligne = _x;
            (_gardes findIf { (_ligne find ("[" + _x + "]")) > -1 }) != -1
        };
    };
};

// ─── Coupe aux N dernières ───
if (_max > 0 && { count _l > _max }) then {
    _l = _l select [(count _l) - _max, _max];
};

// ─── En-tête ───
// Remplissage à la main : BIS_fnc_numberPadded n'existe pas.
private _pad = { if (_this < 10) then { "0" + str _this } else { str _this } };

private _st = systemTime;
private _date = if (count _st >= 6) then {
    format ["%1-%2-%3 %4:%5:%6",
        _st select 0,
        (_st select 1) call _pad,
        (_st select 2) call _pad,
        (_st select 3) call _pad,
        (_st select 4) call _pad,
        (_st select 5) call _pad
    ]
} else { "date inconnue" };

// productVersion select 2 vaut 222 pour la 2.22 : on le rend lisible.
private _av = productVersion select 2;
private _armaV = if (_av isEqualType 0) then {
    format ["%1.%2", floor (_av / 100), (_av % 100) call _pad]
} else { str _av };

private _mods = [];
if (!isNil "cbaestactive" && { cbaestactive }) then { _mods pushBack "CBA" };
if (!isNil "aceestactive" && { aceestactive }) then { _mods pushBack "ACE" };
if (!isNil "opforactive"  && { opforactive })  then { _mods pushBack "ProjectOPFOR" };
if (!isNil "afrfactive"   && { afrfactive })   then { _mods pushBack "RHS-AFRF" };
if (!isNil "usafactive"   && { usafactive })   then { _mods pushBack "RHS-USAF" };
if (!isNil "grefactive"   && { grefactive })   then { _mods pushBack "RHS-GREF" };
if (!isNil "safactive"    && { safactive })    then { _mods pushBack "RHS-SAF" };
if (_mods isEqualTo []) then { _mods = ["aucun detecte"] };

// ─── État du registre de factions ───
private _reg = "module factions non charge";
if (!isNil "hds_factions_pret") then {
    if (!hds_factions_pret) then {
        _reg = "scan en cours";
    } else {
        private _parSide = [];
        {
            _parSide pushBack format ["%1:%2", _x, count _y];
        } forEach hds_factions_par_side;
        _reg = format ["%1 factions (%2)", count hds_factions, _parSide joinString " "];
    };
};

private _r = "";
_r = _r + "===== RAPPORT HDS =====" + endl;
_r = _r + format ["date      : %1", _date] + endl;
_r = _r + format ["machine   : %1 (joueurs: %2)", hds_journal_machine, count allPlayers] + endl;
_r = _r + format ["mission   : %1", briefingName] + endl;
_r = _r + format ["carte     : %1", worldName] + endl;
_r = _r + format ["version   : HDS %1 / Arma %2",
        (if (isNil "hdsversion") then { "?" } else { hdsversion }), _armaV] + endl;
_r = _r + format ["mods      : %1", _mods joinString ", "] + endl;
_r = _r + format ["factions  : %1", _reg] + endl;
_r = _r + format ["compteurs : %1 erreur(s), %2 alerte(s)", hds_journal_erreurs, hds_journal_alertes] + endl;
_r = _r + format ["lignes    : %1 sur %2 en tampon", count _l, count hds_journal] + endl;
_r = _r + "=======================" + endl;

if (_l isEqualTo []) then {
    _r = _r + "(aucune ligne - rien a signaler, ou seuil trop strict)" + endl;
} else {
    // Chaque ligne est tronquée. Sans ça, une seule entrée peut contenir
    // le source complet d'un script et noyer tout le rapport — c'est ce
    // qui est arrivé au premier essai.
    {
        private _ligne = _x;
        if (count _ligne > 700) then {
            _ligne = (_ligne select [0, 700]) + " […tronque]";
        };
        _r = _r + _ligne + endl;
    } forEach _l;
};

_r
