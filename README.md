This project, not yet very organized, is working toward a general purpose bike map with visual hierachies specific to a particular way of cycling. 

## Dependencies ##
- [OSRM-backend](https://github.com/Project-OSRM/osrm-backend)
- PostGIS
- Python and psycopg2
- osm2psql

## TODO ##
There are several big domains of work that remains to be done, outlined and subdivided below. 

* Map simplification
    * Simplify split ways ([example](https://www.openstreetmap.org/#map=19/43.79249/-79.44591)) into single lines (all zoom levels). I'm working on finding these systematically with [Overpass](https://gist.github.com/Nate-Wessel/e7d72da7c7c12e00a472b41537334f8d). 
    * Use hierarchy in map reduction for low zoom levels. Research needed on appropriate algorithms/techniques.
    * Re-cluster split edges based on betweenness value of subsegments and name/way contiguity. 
    * Smooth and resample DEM (GRASS). Alternatively convert to simplified contour polygons to reduce size of vector derivatives. 
    * ... 

* OSM data verification and cleanup
    * Systematically verify/survey bicycle facilities
    * Once it is finalized [what landuse data](overpass/context.txt) will be included in the map, these will need to be verified/refined in some cases. 

* Route Selection
    * Decide on representative route-selection strategy and ensure this is instantiated in the [OSRM bike.lua profile](osrm-profiles/default-bicycle.lua), or create such a profile.
    * ...

## Notes to self ##

Running OSRM:
- `cd scripts/osrm-backend`
- `build/osrm-extract -p profiles/bicycle.lua osm-data/gta.osm`
- `build/osrm-contract osm-data/gta.osrm`
- `build/osrm-routed osm-data/gta.osrm`
