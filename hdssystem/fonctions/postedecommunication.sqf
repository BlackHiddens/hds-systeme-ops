/*
 * fnc_hds_poste_de_communication
 * Initialise les postes de communication (terminal radio/tactique).
 * Params: [liste_objets]
 * Appele cote client (initplayerlocal) — chaque joueur ajoute l'action localement.
 */

params [["_LesPostes", []]];

// Filtrer les nil/objNull AVANT la boucle — isEqualType retourne false pour nil (sans erreur)
private _postesValides = _LesPostes select { _x isEqualType objNull && !isNull _x };

if (count _postesValides == 0) exitWith {
    diag_log "[HDS] poste_de_communication : aucun poste valide (objets non encore synchronises ?)";
};

{
    _x addAction [
        "<img image='\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa' size='1.5'/> <t color='#00aaff'>Terminal de communication</t>",
        {
            params ["_target", "_caller"];
            hint parseText format [
                "<t size='1.1' color='#00aaff'><b>Poste de communication</b></t><br/>" +
                "<t size='0.85'>Terminal operationnel.<br/>Utilisateur : %1<br/>Canal radio actif.</t>",
                name _caller
            ];
        },
        [],
        -1,
        false,
        true,
        "",
        "true",
        5
    ];
} forEach _postesValides;
