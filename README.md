This project, not yet very organized, is working toward a general purpose bike map with visual hierachies specific to a particular way of cycling. 

## Dependencies ##
- [OSRM-backend](https://github.com/Project-OSRM/osrm-backend)
- PostGIS
- Python and psycopg2
- osm2psql

## Notes to self ##
Refresh Data:
`wget -O gta.osm --post-file=bike-map/overpass-query.txt https://overpass-api.de/api/interpreter`

Load OSM in PostGIS for mapping: 
`osm2pgsql --slim --hstore-all --prefix gta -d bikemap --style bike-map/osm2pgsql.style gta.osm`

Generate segments:


Running OSRM:

- `cd scripts/osrm-backend`
- `build/osrm-extract -p profiles/bicycle.lua osm-data/gta.osm`
- `build/osrm-contract osm-data/gta.osrm`
- `build/osrm-routed osm-data/gta.osrm`
