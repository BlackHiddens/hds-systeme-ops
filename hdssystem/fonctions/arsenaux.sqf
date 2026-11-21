/*
 * fnc_hds_arsenaux
 * Initialise les objets arsenal virtuels.
 * Params: [liste_objets]
 */

params ["_Lesarsenales"];

{
    if (aceestactive) then {
        if (boutiqueactive) then {
            [_x, hds_txt_fonctions_arsenal_libinteraction, "Hacker", 0.5, 5, false,
             format ["[%1] spawn fnc_hds_boutique;", _x], 0] spawn fnc_hds_ajoutaction;
        } else {
            if (modehardactive) then {
                // mode hard : arsenal restreint (stub pour test)
                ["AmmoboxInit", [_x, true, {(_this distance _target) < 5}]] call BIS_fnc_arsenal;
            } else {
                // ACE + pas de boutique + pas hard → arsenal ACE complet
                [_x, true] call hds_fnc_arsenal;
                ["AmmoboxInit", [_x, true, {(_this distance _target) < 5}]] call BIS_fnc_arsenal;
            };
        };
    } else {
        // Vanilla : arsenal BIS standard
        ["AmmoboxInit", [_x, true, {(_this distance _target) < 5}]] call BIS_fnc_arsenal;
    };
} forEach (_this select 0);
