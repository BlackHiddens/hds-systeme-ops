params ["_ClassAvion","_camps","_ClassMunition"];

   openMap true;
   ClassAvion = (_this select 0);
   CampsAvion = (_this select 1);
   ClassMunition = (_this select 2);

   ModeAppelRenfort = true;
   Commandepasser = false;
   publicVariable "ModeAppelRenfort";
   publicVariable "Commandepasser";
   hint "Où avez-vous besoin d'un appui Monsieur";
   onMapSingleClick {
    if (ModeAppelRenfort) then {

      _Avions = [
      ([_pos,500,800,1,1,100,1] call BIS_fnc_findSafePos), //position désiré
      _pos getDir (getpos leader player),
      ClassAvion, //Classe de l'avion utilisé
      CampsAvion, //faction
      true //position précise
      ] call bis_fnc_spawnvehicle;


      (_Avions select 2) addWaypoint [_pos,0];
      (_Avions select 2) addWaypoint [([_pos,1000,1000,10,0,30,0] call BIS_fnc_findSafePos),0];

      positionactuelle = _pos;
      Avion = (_Avions select 0);
      Commandepasser = true;
      publicVariable "Commandepasser";
      openMap false;

      };
    ModeAppelRenfort = false;
    publicVariable "ModeAppelRenfort";
  };

waitUntil {Commandepasser};

waitUntil {[[positionactuelle,100],getpos Avion] call bis_fnc_intrigger};
sleep 3; //temps avant apres le passage de l'avion afin de faire exploser la minution
Bombe = ClassMunition createVehicle positionactuelle; //Création de la minition
Bombe setdamage 1; //Destruction de la minition
sleep 30; //Temps avant suppréssion de l'avion
deleteVehicle Avion;
{deleteVehicle _x} foreach (crew Avion);
