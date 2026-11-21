/*
 * fnc_generer_groupe
 * ─────────────────────────────────────────────────────────────
 * Fait venir une petite équipe alliée près du joueur appelant, qui
 * rejoint son groupe.
 *
 * 0 : <STRING|NUMBER> intention ou rôle demandé au registre.
 *                     Une chaîne est passée telle quelle (FIRETEAM,
 *                     SQUAD, RECON, SUPPORT…). Un nombre vient des
 *                     anciens appels et est ignoré : on prend FIRETEAM.
 * 1 : <ANY>           ignoré, conservé pour la compatibilité
 * 2 : <ANY>           ignoré, conservé pour la compatibilité
 *                     (c'était le choix du camouflage R.O.S)
 *
 * Côté client : on ne fait que transmettre. Le serveur a le registre de
 * factions, et c'est à lui que doivent appartenir les hommes.
 *
 * Exemple :
 *   ["FIRETEAM"] call fnc_generer_groupe;
 */

if (isDedicated) exitWith {};

params [["_intention", "FIRETEAM"], ["_compat1", ""], ["_compat2", ""]];

// Les anciens appels passaient un numéro de roster : il n'a plus de sens
// depuis que la composition vient du registre.
if (!(_intention isEqualType "")) then { _intention = "FIRETEAM" };

[getPos player, CampsRenfortAllie, player, true, 10, 30, _intention]
    remoteExec ["fnc_hds_renfortSpawn", 2];

systemChat "Équipe en approche, elle rejoindra votre groupe.";
