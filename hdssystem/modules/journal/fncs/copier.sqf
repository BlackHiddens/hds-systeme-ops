/*
 * hds_fnc_journalCopier
 * ─────────────────────────────────────────────────────────────
 * Met le rapport dans le presse-papier. C'est la voie courte : tu
 * joues, ça casse, tu copies, tu colles. Pas de RPT à aller chercher.
 *
 * 0 : <NUMBER> nombre de lignes, les plus récentes (défaut 120)
 * 1 : <STRING> niveau minimum ("" = tout le tampon)
 *
 * Retourne : <BOOL> true si la copie a eu lieu
 *
 * Utilisation :
 *   - fenêtre « HDS — Outils admin » : Échap → entrée HDS (admins)
 *   - ou dans la console de debug :  call hds_fnc_journalCopier
 *   - tout le tampon, sans filtre :  [0, ""] call hds_fnc_journalCopier
 *   - erreurs seules :               [0, "ERREUR"] call hds_fnc_journalCopier
 *
 * Le plafond par défaut est là pour que le presse-papier reste
 * collable : 300 lignes de RPT, ça fait beaucoup à relire.
 */

params [["_max", 120], ["_niveauMin", ""]];

if (isDedicated) exitWith {
    diag_log "[HDS][JOURNAL] copyToClipboard impossible sur un serveur dedie - utiliser outils\extraire-log.ps1";
    false
};

private _r = [_max, _niveauMin] call hds_fnc_journalRapport;

copyToClipboard _r;

private _nb = count (_r splitString endl);
hint parseText format [
    "<t size='1.1' color='#00aaff'><b>Journal HDS copié</b></t><br/>"
  + "<t size='0.9'>%1 lignes dans le presse-papier.<br/>"
  + "%2 erreur(s), %3 alerte(s) depuis le début.</t>",
    _nb, hds_journal_erreurs, hds_journal_alertes
];

diag_log format ["[HDS][JOURNAL] Rapport copie dans le presse-papier (%1 lignes)", _nb];

true
