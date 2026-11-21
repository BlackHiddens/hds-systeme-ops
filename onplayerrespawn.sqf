#include "mes-parametres.sqf"

// Rechargement des traits au respawn
if (aceestactive) then {
    {
        if (vehicleVarName player isEqualTo _x) then {
            player setVariable ["ace_medical_medicClass", 1, true];
            player setUnitTrait ["Medic", true];
        };
    } forEach sontdesmedecins;
};

{
    if (vehicleVarName player isEqualTo _x) then {
        player setUnitTrait ["engineer", true];
        player setUnitTrait ["explosiveSpecialist", true];
    };
} forEach sontdesingenieurs;
