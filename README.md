This project, not yet very organized, is working toward a general purpose bike map with visual hierachies specific to a particular way of cycling. 

## Dependencies ##
- [OSRM-backend](https://github.com/Project-OSRM/osrm-backend)
- PostGIS
- Python and psycopg2
- osm2psql

## TODO ##
There are several big domains of work that remains to be done, outlined and subdivided below. 

* Map simplification
    * Simplify split ways ([example](https://www.openstreetmap.org/#map=19/43.79249/-79.44591)) into single lines (all zoom levels)
    * Use hierarchy in map reduction for low zoom lvels. Research needed on algorithms/techniques.
    * Re-cluster split edges based on betweenness value and name/way contiguity. 
    * Smooth and resample DEM (GRASS). Alternatively convert to simplified contour polygons. 
    * ... 

* OSM data verification and cleanup
    * Systematically verify/survey bicycle facilities
    * ...

* Route Selection
    * Decide on representative route-selection strategy and ensure this is instantiated in the [OSRM bike.lua profile](https://github.com/Project-OSRM/osrm-backend/blob/master/profiles/bicycle.lua), or create such a profile.
    * ...

## Notes to self ##

Running OSRM:
- `cd scripts/osrm-backend`
- `build/osrm-extract -p profiles/bicycle.lua osm-data/gta.osm`
- `build/osrm-contract osm-data/gta.osrm`
- `build/osrm-routed osm-data/gta.osrm`
