//Paramétrage de de l'ajout de l'action gcam

//Paramétrage du changement automatique de l'equipement
  if(sauvegarderlesequipements)then{
    [player,[ProfileNameSpace,"hdssystem|456987"]] call BIS_fnc_loadInventory;
  };

  //Configuration des médecins-----------------------------------------
  {
    if(vehiclevarname player isequalto _x)then{
  }
  } foreach sontdesmedecins;
  //---------------------------------------------------------------------

  //configuration des expert en transmission-----------------------------
  {
    if(vehiclevarname player isequalto _x)then{

  }
  } foreach sontdesexpertcoms;
  //----------------------------------------------------------------------

  //Configuration des manageurs-------------------------------------------
  {
    if(vehiclevarname player isequalto _x)then{
    };
  } foreach sontdesmanageurs;
  //-----------------------------------------------------------------------

  //Configuration des ingénieurs-------------------------------------------
  {
    if(vehiclevarname player isequalto _x)then{
  };
  } foreach sontdesingenieurs;
  //------------------------------------------------------------------------
  //Configuration des pilotes
  {
    if(vehiclevarname player isequalto _x)then{
  };
  } foreach sontdespilotes;
  //Configuration des contractor
  {
    if(vehiclevarname player isequalto _x)then{
    player setUnitTrait ["engineer",true];
    player setUnitTrait ["explosiveSpecialist",true];
    player setVariable ["ace_medical_medicClass",1,true];
    player setUnitTrait ["Medic",true];
    player setUnitTrait ["UAVHacker",true];
    //player addAction ["mon arsenal privé",{["Open",true] spawn BIS_fnc_arsenal},[],-1,false];
  };
  } foreach sontdescontractor;

//Paramétrage de l'ajout de l'action Contacter des renfort
