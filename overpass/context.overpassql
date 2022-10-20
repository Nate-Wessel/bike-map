// define a global bounding box (s,w,n,e)
[bbox:43.56,-79.65,43.87,-79.11];

// Toronto boundary by id for clipping the data later
rel(324211)->.TO;
rel(324211); map_to_area->.TOarea;


// select ways and relations of interest from within the bounding box
(

	way[waterway~'river*'];
	rel[waterway=riverbank];
  
	way[natural~'wood|beach|wetland|water'];
	rel[natural=water];
	node[natural=tree];

	nwr[leisure~'^park$|golf_course|nature_reserve'];
  
	nwr[landuse~'cemetery|industrial|railway|forest|retail'];
	way[man_made=wastewater_plant];

	nwr[building=retail];

	nwr[amenity=university];

	way[railway];
	
	way[highway~'motorway*'];
	way[highway=service][service=alley];

	nwr[aeroway~'runway|aerodrome|taxiway|terminal'];

	nwr[shop=bicycle];
	nwr[amenity=bicycle_rental];

	.TO; // the city relation itself

)->.prefilter;

// clip to Toronto
nwr.prefilter(area.TOarea)->.clipped;

(.clipped;>;); 

out body;
