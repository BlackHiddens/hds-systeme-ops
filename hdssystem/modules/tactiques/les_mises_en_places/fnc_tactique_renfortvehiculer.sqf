params ["_centre","_nomclassgroupe","_distanceApproche","_camps","_vehiculeTT","_nombredegroupe"];

// _centre peut être un nom de marqueur (string) ou une position [x,y,z]
if (_centre isEqualType "") then {
    _centre = getMarkerPos _centre;
};

//véhicule
private _custom_distance_approche = _distanceApproche;
if (_vehiculeTT iskindof "Air") then {
    _custom_distance_approche = _custom_distance_approche * 3;
} else {
    _custom_distance_approche = _custom_distance_approche * 1.5;
};

private _PositionDeDepart = ([_centre, _custom_distance_approche, (_custom_distance_approche * 1.5), 5, 0, 20] call BIS_fnc_findSafePos);
private _Listederoute = _PositionDeDepart nearroads 200;
private _tentative = 0;

while {(isnil "_Listederoute") and (_tentative < 6)} do {
    _PositionDeDepart = ([_centre, _distanceApproche, (_distanceApproche * 2), 5, 0, 20] call BIS_fnc_findSafePos);
    _Listederoute = _PositionDeDepart nearroads 200;
    _tentative = _tentative + 1;
};

// Si des routes trouvées, partir depuis une route aléatoire
if (!isnil "_Listederoute" && {count _Listederoute > 0}) then {
    _PositionDeDepart = getpos (selectrandom _Listederoute);
};
// Sinon on garde _PositionDeDepart issu de BIS_fnc_findSafePos (pas de route proche)

private _vehicule = [
    _PositionDeDepart,
    0,
    _vehiculeTT,
    _camps
] call bis_fnc_spawnvehicle;

//le groupe de combat
private _liste_groupes = [];

for "_i" from 1 to _nombredegroupe do {
    private _groupedecombat = [
        ([_centre, _custom_distance_approche, (_custom_distance_approche * 1.5), 1, 0, 60] call BIS_fnc_findSafePos),
        _camps,
        _nomclassgroupe
    ] call bis_fnc_spawngroup;
    _liste_groupes append [_groupedecombat];
    // monter dans le vehicule
    {_x moveInCargo (_vehicule select 0)} foreach units _groupedecombat;
    // supprimer le personnel non embarqué
    {
        if !(_x in (_vehicule select 0)) then {
            deleteVehicle _x;
        };
    } foreach units _groupedecombat;
};

[_centre, _vehicule, _liste_groupes] spawn fnc_tactique_missionrenforcer;
