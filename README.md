This project, not yet very organized, is working toward a general purpose bike map with visual hierachies specific to a particular way of cycling. 

## Dependencies ##
- [OSRM-backend](https://github.com/Project-OSRM/osrm-backend)
- PostGIS
- Python and psycopg2
- osm2psql

## Notes to self ##

Running OSRM:
- `cd scripts/osrm-backend`
- `build/osrm-extract -p profiles/bicycle.lua osm-data/gta.osm`
- `build/osrm-contract osm-data/gta.osrm`
- `build/osrm-routed osm-data/gta.osrm`
