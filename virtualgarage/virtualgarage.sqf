if!(isnil "estungarage")then{
DCON_Garage_Enabled = 2;
// 0 : désactivé
// 1 : activé et notifier
// 2 : activé et non notifié

	DCON_fnc_Garage = {
	if !(isNull(uiNamespace getVariable [ "DCON_Garage_Display", objNull ])) exitwith {};

	if(isNil "DCON_Garage_SpawnType") then {
		DCON_Garage_SpawnType = 0;
	};

	_pos = (estungarage select 1);
	_dir = 50;
	_spawns = [];

	_helipad = "Land_HelipadEmpty_F" createVehicleLocal _pos;
	waitUntil{!isNull _helipad};

	_helipad setPos _pos;

	BIS_fnc_arsenal_fullGarage = true;
	BIS_fnc_garage_center = _helipad;
	DCON_Garage_CanSpawn = 0;
	DCON_Garage_Vehicle = objNull;

	DCON_Garage_Color = [0,0,0,1];

	comment "no idea what this does but it works";
	disableSerialization;

	_display = findDisplay 46 createDisplay "RscDisplayGarage";
	uiNamespace setVariable ["DCON_Garage_Display", _display];

	_xPos = safezoneX + safezoneW;
	_yPos = safezoneY + safezoneH;

	_yPos = _yPos - 0.11;

	comment "select spawn type";
	_combo = _display ctrlCreate ["RscCombo", -1];
	_combo ctrlSetPosition [0.3455,_yPos,0.304,0.04];
	_combo ctrlSetFont "PuristaMedium";
	_combo ctrlSetTooltip "Spawn Type";
	_combo ctrlSetEventHandler ["LBSelChanged",
	'
		DCON_Garage_SpawnType = _this select 1;
	'];
	_combo lbAdd "None";
	_combo lbAdd "Getin Driver";
	_combo lbAdd "Flying";

	_combo lbSetCurSel DCON_Garage_SpawnType;

	_combo ctrlCommit 0;

	_yPos = _yPos - 0.07;

	comment "r/woooosh";
	_btn = _display ctrlCreate ["RscButton", -1];
	_btn ctrlSetPosition [0.3455,_yPos,0.304,0.06];
	_btn ctrlSetText str_hds_virtualgarage_acheter;
	_btn ctrlSetFont "PuristaMedium";
	_btn ctrlSetTooltip hds_txt_virtualgarage_description;
	_btn ctrlSetEventHandler ["MouseButtonUp",
	'
		_display = (uiNamespace getVariable "DCON_Garage_Display");

		DCON_Garage_CanSpawn = 1;

		_display closeDisplay 1;

	'];
	_btn ctrlCommit 0;

	comment "part of the function that doesn't work for some reason";
	_slider = _display ctrlCreate ["RscXSliderH", -1];
	_slider ctrlSetPosition [0,0.5,1,0];
	_slider ctrlSetBackgroundColor [0,0,0,0.4];
	_slider ctrlSetText "SPAWN";
	_slider ctrlSetFont "PuristaMedium";
	_slider ctrlSetTooltip "WooOOOOSH!!";
	_slider ctrlSetEventHandler ["SliderPosChanged",'
		_value = (_this select 1)  / 10;

		DCON_Garage_Color set [0,_value];

		[] call DCON_fnc_Garage_UpdateColor;
	'];
	_slider ctrlCommit 0;

	_controls = allControls _display;

	comment "I sat here for about an hour manually going through each control trying to find the ones I hated. See my pain";
	_spawn = _controls spawn {
		if true exitWith {};
		{
			hint str _x;
			_x ctrlSetBackgroundColor [1, 0, 0, 1];
			sleep 1;
		} forEach _this;
	};
	_spawns pushBack _spawn;

	comment "they come back for some reason idk";
	_spawn = _display spawn {
		while{true} do {
			(_this displayCtrl 28644) ctrlShow false;
			(_this displayCtrl 25815) ctrlShow false;
			(_this displayCtrl 44347) ctrlEnable false;
			comment "(_this displayCtrl 44046) ctrlShow false";
			sleep 0.01;
		};
	};
	_spawns pushBack _spawn;

	comment "The intent is to provide players with a sense of pride and accomplishment by pressing the enter key";
	_display displayAddEventHandler ["KeyUp",{
		_key = _this select 1;

		if(_key == 28) then {
			_display = (uiNamespace getVariable "DCON_Garage_Display");

			_display closeDisplay 1;

			DCON_Garage_CanSpawn = 1;
			[] call DCON_fnc_Garage_CreateVehicle;
		};
	}];

	_spawn = [_pos,_dir] spawn {
		_pos = _this select 0;
		_dir = _this select 1;
		_found = false;

		while {true} do {
			_objs = [_pos select 0,_pos select 1] nearEntities [["Air", "Car", "Tank", "Ship", "staticWeapon"], 30];
			reverse _objs;

			_model = uiNamespace getVariable "bis_fnc_garage_centertype";
			_model = _model splitString ":" select 0;
			if(_model find "\a3\" == -1) then {
				_model = "\"+_model;
			};
			if(_model find ".p3d" == -1) then {
				_model = _model+".p3d";
			};

			{
				_found = DCON_Garage_Vehicle getVariable "dcon_garage_veh";
				if(!isNil "_found") exitWith {};

				_id = _x call BIS_fnc_netId;
				_info = (getModelInfo _x) select 1;
				if(_info find "\a3\" == -1) then {
					_info = "\"+_info;
				};
				if(_info find ".p3d" == -1) then {
					_info = _info+".p3d";
				};
				_ignore = _x getVariable "dcon_garage_veh";

				if(_id find "0:" >= 0 && _info == _model && isNil "_ignore") exitWith {
					_veh = _x;

					_veh setVariable ["dcon_garage_veh",true];
					_veh setPlateNumber "DCON <3";

					DCON_Garage_Vehicle = _veh;

					_display = (uiNamespace getVariable "DCON_Garage_Display");
					_ctrls = [];
					if!(isnil "DCON_Garage_Loadout_Controls")then{
						{
							ctrlDelete (_x select 0);
						} forEach DCON_Garage_Loadout_Controls;
					};

					DCON_Garage_Loadout_Controls = [];

					_pylons = (configProperties [configFile >> "CfgVehicles" >> typeOf _veh >> "Components" >> "TransportPylonsComponent" >> "Pylons"]) apply {configName _x};
					if(count _pylons == 0) exitWith {};

					_last_loadout = (uiNamespace getVariable format ["DCON_Garage_Loadout_%1",typeOf _veh]);

					{
						_ctrl = _display ctrlCreate ["RscCombo", -1];
						_ctrl setVariable ["test","worked!"];
						_ctrl ctrlSetTooltip "Select Weapon";
						_ctrl ctrlSetBackgroundColor [0,0,0,0.8];
						_ctrl ctrlSetFade 0.2;
						_ctrl ctrlCommit 0;

						_veh animateBay [_forEachIndex, 1];

						if(!isNil "_last_loadout") then {
							_veh setPylonLoadOut [_forEachIndex+1, _last_loadout select _forEachIndex,true];
						};

						_ctrl_index = _forEachIndex;

						_current_wep = (getPylonMagazines (_veh)) select _forEachIndex;

						_selected = -1;

						_weps = ["PylonRack_1Rnd_Missile_AA_04_F","PylonMissile_1Rnd_Missile_AA_04_F","PylonRack_1Rnd_AAA_missiles","PylonMissile_1Rnd_AAA_missiles","PylonRack_1Rnd_GAA_missiles","PylonMissile_1Rnd_GAA_missiles","PylonRack_1Rnd_Missile_AGM_02_F","PylonRack_3Rnd_Missile_AGM_02_F","PylonRack_1Rnd_LG_scalpel","PylonMissile_1Rnd_LG_scalpel","PylonRack_3Rnd_LG_scalpel","PylonRack_4Rnd_LG_scalpel","PylonRack_7Rnd_Rocket_04_HE_F","PylonRack_7Rnd_Rocket_04_AP_F","PylonRack_12Rnd_PG_missiles","PylonRack_12Rnd_missiles","PylonMissile_1Rnd_Bomb_04_F","PylonMissile_1Rnd_Mk82_F","PylonWeapon_300Rnd_20mm_shells","PylonWeapon_2000Rnd_65x39_belt","PylonRack_20Rnd_Rocket_03_HE_F","PylonRack_20Rnd_Rocket_03_AP_F","PylonRack_19Rnd_Rocket_Skyfire","PylonRack_1Rnd_Missile_AA_03_F","PylonMissile_1Rnd_Missile_AA_03_F","PylonRack_1Rnd_Missile_AGM_01_F","PylonMissile_1Rnd_Bomb_03_F","PylonMissile_Missile_AMRAAM_C_x1","PylonRack_Missile_AMRAAM_C_x1","PylonRack_Missile_AMRAAM_C_x2","PylonMissile_Missile_AMRAAM_D_x1","PylonMissile_Missile_AMRAAM_D_INT_x1","PylonRack_Missile_AMRAAM_D_x1","PylonRack_Missile_AMRAAM_D_x2","PylonMissile_Missile_BIM9X_x1","PylonRack_Missile_BIM9X_x1","PylonRack_Missile_BIM9X_x2","PylonMissile_Missile_AGM_02_x1","PylonMissile_Missile_AGM_02_x2","PylonRack_Missile_AGM_02_x1","PylonRack_Missile_AGM_02_x2","PylonMissile_Bomb_GBU12_x1","PylonRack_Bomb_GBU12_x2","PylonMissile_Missile_AA_R73_x1","PylonMissile_Missile_AA_R77_x1","PylonMissile_Missile_AA_R77_INT_x1","PylonMissile_Missile_AGM_KH25_x1","PylonMissile_Missile_AGM_KH25_INT_x1","PylonMissile_Bomb_KAB250_x1","PylonRack_4Rnd_BombDemine_01_F","PylonRack_4Rnd_BombDemine_01_Dummy_F","PylonMissile_1Rnd_BombCluster_01_F","PylonRack_2Rnd_BombCluster_01_F","PylonMissile_1Rnd_BombCluster_02_F","PylonMissile_1Rnd_BombCluster_02_cap_F","PylonMissile_1Rnd_BombCluster_03_F","PylonRack_2Rnd_BombCluster_03_F","Pylon_1Rnd_Leaflets_West_F","Pylon_1Rnd_Leaflets_East_F","Pylon_1Rnd_Leaflets_Guer_F","Pylon_1Rnd_Leaflets_Civ_F","Pylon_1Rnd_Leaflets_Custom_01_F","Pylon_1Rnd_Leaflets_Custom_02_F","Pylon_1Rnd_Leaflets_Custom_03_F","Pylon_1Rnd_Leaflets_Custom_04_F","Pylon_1Rnd_Leaflets_Custom_05_F","Pylon_1Rnd_Leaflets_Custom_06_F","Pylon_1Rnd_Leaflets_Custom_07_F","Pylon_1Rnd_Leaflets_Custom_08_F","Pylon_1Rnd_Leaflets_Custom_09_F","Pylon_1Rnd_Leaflets_Custom_10_F","PylonMissile_Missile_HARM_x1","PylonRack_Missile_HARM_x1","PylonMissile_Missile_HARM_INT_x1","PylonRack_Bomb_SDB_x4","PylonMissile_Missile_KH58_x1","PylonMissile_Missile_KH58_INT_x1"];
						{
							_ctrl lbAdd getText (configFile >> "CfgMagazines" >> _x >> "DisplayName");
							_ctrl lbSetData [_forEachIndex, format["%1^%2",_x,_ctrl_index+1]];

							if(_current_wep == _x) then {
								_selected = _forEachIndex;
							};
						} forEach _weps;

						_ctrl lbSetCurSel _selected;

						_ctrl ctrlAddEventHandler ["LBSelChanged",{
							_veh = DCON_Garage_Vehicle;
							_ctrl = _this select 0;
							_index = _this select 1;
							_str = (_ctrl lbData _index) splitString "^";
							_pylon_index = parseNumber (_str select 1);
							_class = (_str select 0);

							_veh setPylonLoadOut [_pylon_index, _class,true];

							(uiNamespace setVariable [format ["DCON_Garage_Loadout_%1",typeOf _veh],getPylonMagazines _veh]);

							playSound3D ["a3\missions_f_beta\data\sounds\firing_drills\target_pop-down_small.wss",_veh,false,getPos _veh,2];
						}];

						_ctrl ctrlAddEventHandler ["MouseEnter",{
							(_this) ctrlSetFade 0;
							(_this) ctrlCommit 0;
						}];
						_ctrl ctrlAddEventHandler ["MouseExit",{
							(_this) ctrlSetFade 0.5;
							(_this) ctrlCommit 0;
						}];

						_offset = getArray (configfile >> "CfgVehicles" >> typeOf _veh >> "Components" >> "TransportPylonsComponent" >> "pylons" >> _x >> "UIposition");
						_offset_final = +_offset;
						_pos_offset = [-0.33,-0.33,-0.5];
						_multiplyer = [15,15];

						switch (typeOf _veh) do {
							case 'B_Plane_CAS_01_dynamicLoadout_F': {
								_offset_final = [_offset select 1,_offset select 0];
								_pos_offset = [-0.26,-0.36,-0.5];
								_multiplyer = [25,15];
							};
							case 'B_Heli_Light_01_dynamicLoadout_F': {
								_offset_final = [-(_offset select 0),(_offset select 1)];
								_pos_offset = [0.32,-0.5,-0.5];
								_multiplyer = [6,6];
							};
							case 'B_Heli_Attack_01_dynamicLoadout_F': {
								_offset_final = [-(_offset select 0),(_offset select 1)];
								_pos_offset = [0.33,-0.4,-0.5];
								_multiplyer = [6,15];
							};
							case 'O_Heli_Attack_02_dynamicLoadout_F': {
								_offset_final = [-(_offset select 0),(_offset select 1)];
								_pos_offset = [0.33,-0.33,-0.5];
								_multiplyer = [13,13];
							};
							case 'B_T_UAV_03_dynamicLoadout_F': {
								_offset_final = [-(_offset select 0),-(_offset select 1)];
								_pos_offset = [0.31,0.33,-0.5];
								_multiplyer = [10,10];
							};
							case 'O_Heli_Light_02_dynamicLoadout_F': {
								_offset_final = [-(_offset select 0),(_offset select 1)];
								_pos_offset = [0.31,-0.8,-1.6];
								_multiplyer = [9,1];
							};
							case 'I_Heli_light_03_dynamicLoadout_F': {
								_offset_final = [-(_offset select 0),(_offset select 1)];
								_pos_offset = [0.33,-3,-0.5];
								_multiplyer = [9,1];
							};
							case 'I_Plane_Fighter_03_dynamicLoadout_F': {
								_offset_final = [-(_offset select 1),(_offset select 0)];
								_pos_offset = [0.29,-0.33,-0.5];
								_multiplyer = [15,25];
							};
							case 'B_UAV_02_dynamicLoadout_F': {
								_offset_final = [-(_offset select 1),(_offset select 0)];
								_pos_offset = [0.28,-0.22,-0.8];
								_multiplyer = [25,15];
							};
							case 'O_Plane_CAS_02_dynamicLoadout_F': {
								_offset_final = [-(_offset select 1),(_offset select 0)];
								_pos_offset = [0.28,-0.32,-0.8];
								_multiplyer = [24,100];
							};
							case 'O_T_VTOL_02_infantry_dynamicLoadout_F': {
								_offset_final = [-(_offset select 1),(_offset select 0)];
								_pos_offset = [0.28,-0.32,-1.3];
								_multiplyer = [40,20];
							};
							case 'O_T_VTOL_02_vehicle_dynamicLoadout_F': {
								_offset_final = [-(_offset select 1),(_offset select 0)];
								_pos_offset = [0.28,-0.32,-1.3];
								_multiplyer = [40,20];
							};
						};

						_ctrls pushBack [
							_ctrl,
							_offset_final,
							_pos_offset,
							_multiplyer
						];
					} forEach _pylons;

					DCON_Garage_Loadout_Controls = _ctrls;

					["DCON_Garage_FrameEvent", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
					["DCON_Garage_FrameEvent", "onEachFrame", {
						_ctrls = DCON_Garage_Loadout_Controls;
						_veh = DCON_Garage_Vehicle;

						_width = 0.14;
						_height = 0.05;
						_boost = 0;

						_mouse = getMousePosition;

						{
							_ctrl = _x select 0;
							_offset = _x select 1;
							_pos_offset = _x select 2;
							_multiplyer = _x select 3;
							_offset_x = _offset select 0;
							_offset_y = _offset select 1;

							_offset_x = _offset_x + (_pos_offset select 0);
							_offset_y = _offset_y + (_pos_offset select 1);

							_offset_x = _offset_x * 1;
							_offset_y = -_offset_y * 1;

							_offset_x = _offset_x * (_multiplyer select 0);
							_offset_y = _offset_y * (_multiplyer select 1);

							_pos = worldToScreen (_veh modelToWorld [_offset_x,_offset_y,(_pos_offset select 2)]);
							_pos_x = (_pos select 0) - _width/2;
							_pos_y = (_pos select 1) - _height/2;

							_dist = 1 - (_mouse distance _pos);

							if(_dist > 0.94) then {
								_boost = 0;
							}
							else
							{
								_boost = 0;
							};

							_ctrl ctrlSetPosition [_pos_x,_pos_y - _boost,_width,_height];
							_ctrl ctrlCommit 0;

						} forEach _ctrls;

					}] call BIS_fnc_addStackedEventHandler;
				};

			} forEach _objs;

			DCON_Garage_Vehicle setPos _pos;

			sleep 0.1;
		};
	};
	_spawns pushBack _spawn;

	_spawn = [_pos,_dir] spawn {
		_pos = _this select 0;
		_dir = _this select 1;

		while {true} do {
			DCON_Garage_Vehicle setPos _pos;
		};
	};
	_spawns pushBack _spawn;

	waitUntil {
		isNull _display;
	};
	if!(isnil "DCON_Garage_Loadout_Controls")then{
	{
		ctrlDelete (_x select 0);
	} forEach DCON_Garage_Loadout_Controls;
};
	["DCON_Garage_FrameEvent", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
	if!(isnil "DCON_Garage_Loadout")then{terminate DCON_Garage_Loadout};

	deleteVehicle _helipad;

	{
		terminate _x;
	} forEach _spawns;

	_veh = BIS_fnc_garage_center;
	{
		deleteVehicle _x;
	} forEach crew _veh;
	if(pointdevehicule == 0)then{DCON_Garage_CanSpawn = 0};
	if(DCON_Garage_CanSpawn == 1) then {
		[] call DCON_fnc_Garage_CreateVehicle;
	}
	else
	{
		deleteVehicle _veh;
	};

};
publicVariable "DCON_fnc_Garage";

DCON_fnc_Garage_CodeEditor_Open = {
	disableSerialization;

	_garageDisplay = (uiNamespace getVariable "DCON_Garage_Display");

	_display = _garageDisplay createDisplay "RscDisplayGarage";
	uiNamespace setVariable ["DCON_Garage_CodeEditor_Display", _display];

	_bg = _display ctrlCreate ["RscBackground", -1];
	_bg ctrlSetPosition [0.086,0,0.78,0.18];
	_bg ctrlSetBackgroundColor [0,0,0,0.8];
	_bg ctrlCommit 0;

	comment "technically this is exploting, please don't ban me";
	_exec = _display ctrlCreate ["RscAttributeExec", 200];
	_exec ctrlSetPosition [0.086,0,0.78,0.18];
	_exec ctrlCommit 0;

	((_display) displayCtrl 14466) ctrlEnable false;

	ctrlSetFocus ((_display) displayCtrl 13766);

	sleep 3;

	_display closeDisplay 1;
};
publicVariable "DCON_fnc_Garage_CodeEditor_Open";

DCON_fnc_Garage_CreateVehicle = {
	if(pointdevehicule > 0)then{
		pointdevehicule = pointdevehicule - 1;publicVariable "pointdevehicule";
		[format ["Point véhicule = %1 pts<br />",pointdevehicule]] call fnc_fnc_informations;

		_veh  = BIS_fnc_garage_center;

		_type = typeOf _veh;
		_textures = getObjectTextures _veh;
		_animationNames = animationNames _veh;
		_animationValues = [];
		_current_mags = (getPylonMagazines (_veh));
		_special = "CAN_COLLIDE";
		_movein = false;

		{
			_animationValues pushBack (_veh animationPhase _x);
		} forEach _animationNames;

		deleteVehicle _veh;
		waitUntil {!alive _veh};
		sleep 0.1;

		switch (DCON_Garage_SpawnType) do {
			case 1 : {
				_movein = true;
			};
			case 2 : {
				_movein = true;
				_special = "FLY";
			};
		};

		_veh = createvehicle [_type,_pos,[],0,_special];
		_veh setVariable ["dcon_garage_veh",true,true];

		comment "i died about 200 times before implementing this..";
		if!(_veh isKindOf "plane") then {
			_veh setDir _dir;
		};

		clearWeaponCargoGlobal _veh;
		clearMagazineCargoGlobal _veh;

		{
			_veh animate [_x,_animationValues select _forEachIndex,true];
		} forEach _animationNames;

		{
			_veh setObjectTextureGlobal [_forEachIndex,_x];
		} forEach _textures;

		{
			_veh setPylonLoadOut [_forEachIndex+1, _x,true];
		} forEach _current_mags;

		if(_movein) then {
			moveout player;
			waitUntil {vehicle player == player};
			player moveInDriver _veh;
		};

		_veh setPlateNumber "DCON <3";

		comment "clean up your mess..";
		_veh spawn {
			waitUntil {sleep 0.1;!alive _this;};
			sleep 15;
			deleteVehicle _this;
		};
	}else{
		[format ["Pas assez de point de véhicule = %1 pts<br />",pointdevehicule]] call fnc_fnc_informations;

	};

};
publicVariable "DCON_fnc_Garage_CreateVehicle";

DCON_fnc_Garage_UpdateColor = {
	comment "no idea why this doesn't work ¯\_(ツ)_/¯";

	_veh = DCON_Garage_Vehicle;
	_color = DCON_Garage_Color;

	hint str _color;

	_color2 = format ["#(rgb,8,8,3)color(%1,%2,%3,%4)",_color select 0,_color select 1,_color select 2,_color select 3];

	_veh setObjectTexture [0, _color2];
	_veh setObjectTexture [1, _color2];
	_veh setObjectTexture [2, _color2];
	_veh setObjectTexture [3, _color2];
	_veh setObjectTexture [4, _color2];
	_veh setObjectTexture [5, _color2];
};
publicVariable "DCON_fnc_Garage_UpdateColor";

DCON_fnc_Garage_Warn = {
	_unit = _this select 0;
	_id = _this select 1;

	if(!isNil "DCON_Garage_GotWarning" || player == _unit) exitWith {};
	DCON_Garage_GotWarning = true;
	playSound "alarm";

	_display = findDisplay 46;

	_text = parseText format ["<t color='#ff0000' align='center' size='1.4'>%1 utilise le garage virtuel DCON pour faire apparaître des véhicules. Si vous ne les voulez pas dans le jeu, tapez '#kick %2' pour les lancer.</t>",name _unit,_id];

	systemChat format ["Type: '#kick %2' pour supprimer %1 sur le serveur.",name _unit,_id];

	_ctrl = _display ctrlCreate ["RscStructuredText", 1337];
	_ctrl ctrlSetPosition [0,0,1,0.2];
	_ctrl ctrlSetStructuredText _text;
	_ctrl ctrlSetFont "PuristaMedium";
	_ctrl ctrlCommit 0;

	sleep 3;
	playSound "alarm";

	sleep 5;

	ctrlDelete _ctrl;
};
publicVariable "DCON_fnc_Garage_Warn";

comment "holding the users hand";
DCON_fnc_Garage_Init = {
	waitUntil{!isNull findDisplay 46};

	DCON_Garage_Pressed = false;

	if(!isNil "DCON_Garage_KeyDown") then {
		(findDisplay 46) displayRemoveEventHandler ["KeyDown",DCON_Garage_KeyDown];
	};
	DCON_Garage_KeyDown = (findDisplay 46) displayAddEventHandler ["KeyDown",{
		if(inputAction "User13" > 0) then {
			DCON_Garage_Pressed = true;
		}
	}];

	if(!isNil "DCON_Garage_KeyUp") then {
		(findDisplay 46) displayRemoveEventHandler ["KeyUp",DCON_Garage_KeyUp];
	};
	DCON_Garage_KeyUp = (findDisplay 46) displayAddEventHandler ["KeyUp",{
		if(DCON_Garage_Pressed) then {
			DCON_Garage_Pressed = false;
			[] call DCON_fnc_Garage_Open;
		};
	}];

	/* if(!isNil "DCON_Garage_Action_Spawn") then {
		terminate DCON_Garage_Action_Spawn;
		player removeAction DCON_Garage_Action;
	};
	DCON_Garage_Action_Spawn = 0 spawn {
		while {true} do {
			_player = player;
			_estunpilote = false;

					_action = [
				  (estungarage select 0),
				  "<t color='#353531'>Commander un</t>| véhicule",
				  "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
				  "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa",
				  "_this distance _target < 2",
				  "_this distance _target < 2",
				  {},
				  {},
				  {
				    [] call DCON_fnc_Garage_Open;
				  },
				  {},
				  [],
				  0.5,
				  1,
				  false,
				  false
				  ] call BIS_fnc_holdActionAdd;


					DCON_Garage_Action = _action;
					waitUntil {sleep 0.3;player != _player};
					_player removeAction _action;
		};
	}; */

};
publicVariable "DCON_fnc_Garage_Init";

DCON_fnc_Garage_Open = {
	comment "*pats self on back*";
	if(DCON_Garage_Enabled == 0 && isMultiplayer) exitWith {
		hint "garage désactivé par les administrateurs";
	};

	if(DCON_Garage_Enabled == 1 && isMultiplayer) then {
		[player,owner player] remoteExec ["DCON_fnc_Garage_Warn",0,false];
	};

	_pos = (getPos player vectorAdd (eyeDirection player vectorMultiply 15));
	_dir = getDir player;
	[_pos,_dir] spawn DCON_fnc_Garage;
};
publicVariable "DCON_fnc_Garage_Open";

comment "really holding their hand";
[] spawn DCON_fnc_Garage_Init;

};
