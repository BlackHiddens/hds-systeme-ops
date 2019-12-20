/*
 * This file contains parameters to config and function call to start an instance of
 * traffic in the mission. The file is edited by the mission developer.
 *
 * See file Engima\Traffic\Documentation.txt for documentation and a full reference of
 * how to customize and use Engima's Traffic.
 */

 private ["_parameters"];
//hds_liste_vehicule_civil_arabes
//hds_liste_vehicule_civil_europeens
//hds_liste_vehicule_civil_africain
//hds_liste_vehicule_civil_russe


// Set traffic parameters.
_parameters = [
	["SIDE",civilian],
	["VEHICLES",hds_liste_vehicule_civil_europeens],
	["VEHICLES_COUNT",5],
	["MIN_SPAWN_DISTANCE", 300], //250
	["MAX_SPAWN_DISTANCE", 500], //450
	["MIN_SKILL",1],
	["MAX_SKILL",1],
	["DEBUG",hds_engima_debugg]
];

// Start an instance of the traffic
_parameters spawn ENGIMA_TRAFFIC_StartTraffic;
