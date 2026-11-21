/*
 * hds_fnc_proteger
 * ─────────────────────────────────────────────────────────────
 * Exécute du code en attrapant ses erreurs, et les journalise.
 *
 * Utile là où une erreur ne doit pas emporter tout le script : un
 * spawn de groupe au milieu d'une boucle d'occupation, un appel à une
 * fonction d'un mod qui peut ne pas être là, etc.
 *
 * 0 : <CODE>   le code à exécuter
 * 1 : <STRING> source, pour la ligne de journal
 * 2 : <ANY>    arguments passés au code (deviennent son _this)
 *
 * Retourne : [_ok, _sortie]
 *   _ok      <BOOL>  false si une erreur a été attrapée
 *   _sortie  <ARRAY> [] si le code n'a rien renvoyé ou a échoué,
 *                    [valeur] sinon
 *
 * POURQUOI UN TABLEAU ET PAS LA VALEUR DIRECTEMENT
 * En SQF, une variable ne peut pas contenir nil : lui affecter nil la
 * supprime. Et un code dont la dernière instruction ne renvoie rien
 * (setPos, setVectorUp…) laisse la variable d'affectation indéfinie.
 * La lire lève alors « Variable indéfinie dans une expression ».
 * C'est exactement le bug que la première exécution a remonté. On
 * emballe donc le résultat : [] ou [valeur], jamais de nil nu.
 *
 * Exemple :
 *   ([{ _this call hds_fnc_factionGroupe }, "OCCUPATIONS", [east,"GARNISON"]]
 *     call hds_fnc_proteger) params ["_ok", "_sortie"];
 *   if (!_ok) exitWith {};
 *   private _cfg = _sortie param [0, configNull];
 */

params [["_code", {}], ["_source", "HDS"], ["_args", []]];

private _ok = true;
private _sortie = [];

try {
    private _r = _args call _code;
    // _r reste indéfinie si _code ne renvoie rien : on teste par son nom
    // avant de la lire, sinon on déclenche l'erreur qu'on veut éviter.
    if (!isNil "_r") then { _sortie = [_r] };
} catch {
    _ok = false;
    ["ERREUR", _source, format ["Exception attrapee : %1", _exception]] call hds_fnc_log;
};

[_ok, _sortie]
