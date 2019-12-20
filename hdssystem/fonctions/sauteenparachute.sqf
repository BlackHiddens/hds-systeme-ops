params ["_altitude_de_saut","_altitude_critique","_objet"];

fnc_orient = {
  _obj = _this select 0;
  _y = _this select 1;
  _p = _this select 2;
  _r = _this select 3;
  _a = _this select 4;
  _b = _this select 5;
  _c = _this select 6;
  _obj setVectorDirAndUp [
   [ sin _y * cos _p,cos _y * cos _p,sin _p],
   [[ sin _r,-sin _p,cos _r * cos _p],-_y] call BIS_fnc_rotateVector2D
   ]
};

[
(_this select 2),
(format ["<t color='#353531'>%1</t>",hds_txt_fonctions_divers_libsautenparachute]),
"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_takeOff1_ca.paa",
"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_takeOff1_ca.paa",
"_this distance _target < 3",
"_this distance _target < 3",
{},
{},
{
  openmap [true,false];
  titleText[hds_txt_fonctions_divers_descsautenparachute, 'PLAIN'];
  _bpk = createVehicle ["WeaponHolderSimulated",getPosATL player,[],0,"CAN_COLLIDE"];
  if (backpack player !="") then {
   _bpk addBackpackCargoGlobal [backpack player, 1];
   [] spawn {
    ["chute_bpk", "onEachFrame", {
     if (!isNull _bk) then {
      call{
       if (stance player == "UNDEFINED") exitWith {
          _bk attachTo [player,[-0.1,-0.05,-0.7],'leaning_axis'];
         [_bk,0,-180,0,0,0,0] remoteExec ["fnc_orient"]};
       if (stance player == "STAND") exitWith {
          _bk attachTo [player,[-0.1,0.75,-0.05],'leaning_axis'];
         [_bk,0,-90,0,0,0,0] remoteExec ["fnc_orient"]};
     };
    };
   }] call BIS_fnc_addStackedEventHandler;
  };
 };
[(_arguments select 0),(_arguments select 1),(_arguments select 2)]  onMapSingleClick {

  player setPos [_pos select 0,_pos select 1,(_this select 0)];
  [player, [missionNamespace, 'inv']] call BIS_fnc_saveInventory;
   player setVariable ['MGI_ammo1',player ammo (primaryWeapon player)];
   player setVariable ['MGI_ammo2',player ammo (handgunWeapon player)];
   player setVariable ['MGI_ammo3',player ammo (secondaryWeapon player)];
   player setVariable ['MGI_mags',magazinesAmmoFull player];
   player setVariable ['MGI_weapon',currentWeapon player];
  removeBackpackGlobal player;
  player addBackpack 'B_parachute';
  openmap [false,false];
  [(_this select 1)] spawn {
    waitUntil {(getpos player select 2) < (_this select 0) or isTouchingGround player};
    if (!isTouchingGround player) then {player action ['OpenParachute', player]};
    waitUntil {isTouchingGround player};
    if (!isnil "_bk") then {
      detach _bk;
      deleteVehicle _bk};
    sleep 2;
    if (alive player) then {
      [player, [missionNamespace, 'inv']] call BIS_fnc_loadInventory;
      {player removeMagazine _x} forEach magazines player;
      player setAmmo [primaryWeapon player, 0];
      player setAmmo [handGunWeapon player, 0];
      player setAmmo [secondaryWeapon player, 0];
      {if (((player getVariable 'MGI_mags') select _foreachindex select 3) <= 0) then {
        player addMagazine [_x select 0,_x select 1]}} forEach (player getVariable 'MGI_mags');
      player setAmmo [primaryWeapon player,player getVariable 'MGI_ammo1'];
      player setAmmo [handGunWeapon player,player getVariable  'MGI_ammo2'];
      player setAmmo [secondaryWeapon player,player getVariable 'MGI_ammo3'];
      player selectWeapon (player getVariable 'MGI_weapon')
    };
  }
 onMapSingleClick '';
 false};
},
{},
[(_this select 0),(_this select 1),(_this select 2)],
1,
1,
false,
false
] call BIS_fnc_holdActionAdd;
