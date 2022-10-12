// define a global bounding box (s,w,n,e)
[timeout:300][bbox:43.56,-79.65,43.87,-79.11];

// Old Toronto boundary by id for clipping the data later
rel(324211)->.TO;
rel(324211); map_to_area->.TOarea;

// select ways and relations of interest from within the bounding box
(
	way[highway];
  	rel[type=restriction];
	rel[route=bicycle];
)->.streets;

( // clip anything not in or around Toronto
	nwr.streets(area.TOarea);    // in Toronto
	nwr.streets(around.TO:5000); // within 5km of boundary line
);

// join any children of the above ways and relations
(._;>;); 

out body qt;
