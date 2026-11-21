/*
 * fnc_EstUnTerminalRenfort
 * ─────────────────────────────────────────────────────────────
 * Pose sur un objet l'action maintenue « appeler un renfort allié ».
 *
 * 0 : <OBJECT> l'objet porteur, en général un poste de communication
 * 1 : <STRING> libellé de l'action
 *
 * ── Ce qui était cassé ──
 * Trois choses, empilées, qui rendaient l'appel de renfort
 * inatteignable :
 *
 *   1. Personne n'appelait cette fonction. Elle était compilée, et
 *      c'est tout : aucune action n'était jamais posée nulle part.
 *   2. Le code de fin pointait vers
 *      « h-missions\h-modules\h-occupations\... », chemin de l'ancienne
 *      arborescence, qui n'existe plus ici. Même appelée, elle aurait
 *      échoué.
 *   3. Le son d'amorce était « rhs_usa_land_rc_25 », soit une
 *      dépendance RHS pour un bip.
 *
 * On appelle maintenant fnc_renfort_allie directement, et le son part.
 */

params [["_UnObjet", objNull], ["_Message", "Appeler un renfort allié"]];

if (isNull _UnObjet) exitWith { false };

private _icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_call_ca.paa";

[
    _UnObjet,
    format ["<t color='#00aaff'>%1</t>", _Message],
    _icone,
    _icone,
    "_this distance _target < 7",
    "_this distance _target < 7",
    {},
    {},
    { call fnc_renfort_allie },
    {},
    [],
    4,
    0,
    false,
    false
] remoteExec ["BIS_fnc_holdActionAdd", 0, _UnObjet];

true
