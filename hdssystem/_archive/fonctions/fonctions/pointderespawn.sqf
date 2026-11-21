params [];
if (autocreationreapparition) then {
  LemarqueurRespawn = createMarker ["respawn_west_0",getpos (playableUnits select 0)];
  LemarqueurRespawn setmarkerType "Empty";
  LemarqueurRespawn setmarkertext (format ["%1|base",hdsversion]);
  publicVariable "LemarqueurRespawn";
};
