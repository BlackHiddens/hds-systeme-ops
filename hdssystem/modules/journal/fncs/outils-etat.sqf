/*
 * hds_fnc_outilsEtat
 * ─────────────────────────────────────────────────────────────
 * Remplit la ligne d'état de la fenêtre « Outils admin ». Appelée au
 * chargement de la fenêtre (onLoad) et après chaque copie, pour qu'on
 * voie tout de suite ce qui vient d'être mis dans le presse-papier.
 *
 * Aucun paramètre. Retourne <BOOL>.
 *
 * Toutes les lectures passent par getVariable avec défaut : cette
 * fonction s'affiche par-dessus le jeu, elle ne doit jamais être la
 * cause d'une erreur. Un module pas encore chargé donne une ligne
 * incomplète, pas une fenêtre vide.
 */

disableSerialization;

private _f = uiNamespace getVariable ["hds_outils_admin_fenetre", displayNull];
if (isNull _f) then { _f = findDisplay 70101 };
if (isNull _f) exitWith { false };

private _ctrl = _f displayCtrl 70103;
if (isNull _ctrl) exitWith { false };

private _journal  = missionNamespace getVariable ["hds_journal", []];
private _max      = missionNamespace getVariable ["hds_journal_max", 300];
private _erreurs  = missionNamespace getVariable ["hds_journal_erreurs", 0];
private _alertes  = missionNamespace getVariable ["hds_journal_alertes", 0];
private _seuil    = missionNamespace getVariable ["hds_journal_seuil", "INFO"];
private _machine  = missionNamespace getVariable ["hds_journal_machine", "?"];

// Le registre n'existe que sur le serveur : un client ne peut rien en
// dire, et c'est normal. Le bouton reste utilisable — la demande part
// au serveur par remoteExec, c'est lui qui construit le JSON.
private _registre = if (isNil "hds_factions") then {
    "construit sur le serveur"
} else {
    if (missionNamespace getVariable ["hds_factions_pret", false]) then {
        format ["%1 factions", count (keys hds_factions)]
    } else {
        "scan en cours..."
    };
};

private _couleurErr = ["#7fbf7f", "#ff8844"] select (_erreurs + _alertes > 0);

_ctrl ctrlSetStructuredText parseText format [
    "<t size='0.95'>Machine <t color='#00aaff'>%1</t>"
    + "  ·  tampon <t color='#00aaff'>%2</t>/%3 lignes"
    + "  ·  seuil <t color='#00aaff'>%4</t></t><br/>"
    + "<t size='0.95'>Erreurs <t color='%5'>%6</t>"
    + "  ·  alertes <t color='%5'>%7</t>"
    + "  ·  registre <t color='#00aaff'>%8</t></t>",
    _machine, count _journal, _max, _seuil,
    _couleurErr, _erreurs, _alertes, _registre
];

true
