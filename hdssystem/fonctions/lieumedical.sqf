/*
 * fnc_hds_medical
 * Zone de soin automatique autour d'un objet ou véhicule.
 * Params: [objet]
 */

params ["_sujet"];

while {true} do {
    if (aceestactive && lelieuestunvehicule) then {
        if (player inArea [getPos _sujet, 6, 6, 0, false]) then {
            [objNull, player] call ace_medical_treatment_fnc_fullHeal;
            [hds_txt_fonctions_medical_santestable] remoteExecCall ["hint", player];
        };
    };

    if (aceestactive && !(lelieuestunvehicule)) then {
        if (player inArea [getPos _sujet, 6, 6, 0, false]) then {
            [objNull, player] call ace_medical_treatment_fnc_fullHeal;
            [hds_txt_fonctions_medical_santestable] remoteExecCall ["hint", player];
        };
    };

    if (!aceestactive && lelieuestunvehicule) then {
        if (player in _sujet && getDammage player > 0) then {
            player setDammage 0;
            [hds_txt_fonctions_medical_santestable] remoteExecCall ["hint", player];
        };
    };

    if (!aceestactive && !(lelieuestunvehicule)) then {
        if (player inArea [getPos _sujet, 6, 6, 6, false] && getDammage player > 0) then {
            player setDammage 0;
            [hds_txt_fonctions_medical_santestable] remoteExecCall ["hint", player];
        };
    };

    sleep 5;
};
