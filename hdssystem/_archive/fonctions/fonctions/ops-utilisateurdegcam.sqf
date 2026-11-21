params ["_Joueur"];

player addaction ["<t color='#35383B'>G</t>cam",
  {
    [player] execVM "gcam\gcam.sqf";
    _message = format ["%2 : %1 utilise gcam",name player,hdsversion];
    [_message] remoteexeccall ["systemChat",0];
  },[],0,false,true,"","",-1];
