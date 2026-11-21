#include "mes-parametres.sqf"

// ─── Configuration médicale ACE ───
if (aceestactive) then {
    {
        if (vehicleVarName player isEqualTo _x) then {
            player setVariable ["ace_medical_medicClass", 1, true];
            player setUnitTrait ["Medic", true];
        };
    } forEach sontdesmedecins;
};

// ─── Traits ingénieurs ───
{
    if (vehicleVarName player isEqualTo _x) then {
        player setUnitTrait ["engineer", true];
        player setUnitTrait ["explosiveSpecialist", true];
    };
} forEach sontdesingenieurs;

// ─── Traits managers ───
{
    if (vehicleVarName player isEqualTo _x) then {
        player setUnitTrait ["engineer", true];
        player setUnitTrait ["Medic", true];
        if (aceestactive) then { player setVariable ["ace_medical_medicClass", 1, true]; };
    };
} forEach sontdesmanageurs;

// ─── Debug carte (marqueurs ennemis locaux + positions en chat) ───
[] execVM "hdssystem\debug-carte.sqf";

// ─── Lieux de soin (boucle locale par joueur) ───
{ [_x] spawn fnc_hds_medical; } forEach sontdeslieudesoin;

// ─── Postes de communication (action ajoutée localement) ───
[sontdespostesdecommunications] spawn fnc_hds_poste_de_communication;

// ─── Appel de renfort allié ───
// Personne n'appelait fnc_EstUnTerminalRenfort : l'action n'existait
// nulle part, et la fonctionnalité était donc inatteignable. On la pose
// sur deux porteurs.
//
// Sur le poste de communication, pour qui veut jouer le passage par la
// radio. Et sur le chef de groupe lui-même, parce que c'est de lui
// qu'on attend l'appel et qu'il ne doit pas avoir à rentrer à la base
// pour le passer.
[] spawn {
    waitUntil { !isNull player && { player == player } };

    {
        [_x, "Appeler un renfort allié"] call fnc_EstUnTerminalRenfort;
    } forEach (sontdespostesdecommunications select { _x isEqualType objNull && { !isNull _x } });

    player addAction [
        "<t color='#00aaff'>Appeler un renfort allié</t>",
        { call fnc_renfort_allie },
        nil, 1.6, false, true, "",
        "player == leader group player && {!isNil ""NbRenfortDispo""} && {NbRenfortDispo > 0}",
        10
    ];
};

// ─── Outils admin : fenêtre de copie du journal et du registre ───
// Les trois actions de molette d'avant sont parties dans une fenêtre,
// ouverte depuis le menu Échap. Voir hds_fnc_outilsAdminInit.
[] spawn {
    waitUntil { !isNull player && { player == player } };
    call hds_fnc_outilsAdminInit;
};

// ─── Message de bienvenue ───
// Le rappel d'accès ne s'affiche que pour qui en a l'usage : inutile
// d'annoncer les outils admin à toute la partie.
[] spawn {
    sleep 3;

    private _liste = missionNamespace getVariable ["hds_administrateurs", []];
    private _admin = ((getPlayerUID player) in _liste) || { isServer && hasInterface };

    private _txt = "<t size='1.2' color='#00aaff'><b>NewHDS | Stratis</b></t><br/><t size='0.9'>Système chargé.";
    if (_admin) then {
        _txt = _txt + "<br/>Admin : Échap → « HDS — Outils admin ».";
    };
    _txt = _txt + "</t>";

    hint parseText _txt;
};
