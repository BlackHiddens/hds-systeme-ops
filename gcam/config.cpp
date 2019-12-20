// GCam 2.0 Addon Config.cpp
// some basic defines
#define TEast 0
#define TWest 1
#define TGuerrila 2
#define TCivilian 3
#define TSideUnknown 4
#define TEnemy 5
#define TFriendly 6
#define TLogic 7

#define true 1
#define false 0

// type scope
#define private 0
#define protected 1
#define public 2

#define WeaponNoSlot				0// dummy weapons
#define WeaponSlotPrimary		1// primary weapons
#define WeaponSlotSecondary	16// secondary weapons
#define WeaponSlotItem			256// items
#define WeaponSlotBinocular	4096// binocular
#define WeaponHardMounted		65536

#include "gcam_component.hpp"


class CfgPatches
{
	class gcam
	{
		units[] = {};
		weapons[] = {};
		requiredVersion = 0.1;
		requiredAddons[] = {};
	};

};

class CfgVehicles
{
	class Land;
	class Man : Land
	{
		class UserActions
		{
			class gcam_launch
			{
				displayName="GCam";
				position="pos driver";
				onlyforplayer=1;
				radius=10.0;
				condition="this == player";
				statement="[] execVM ""gcam\gcam.sqf""";
			};
		};
	};
	class All {};
	class Static: All {};
	class Building: Static {};
	class NonStrategic: Building {};
	class TargetTraining: NonStrategic {};
	class TargetGrenade: TargetTraining {};

};
