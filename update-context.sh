cd ~/bike-map

# get new landuse/context data from the overpass API
wget -O data/context.osm --post-file=overpass/context.txt https://overpass-api.de/api/interpreter

# import data into postGIS, overwriting old data
osm2pgsql --slim --hstore-all --prefix context -d bikemap --style osm2pgsql/context.style data/context.osm

# generate random vector points representing e.g wooded areas
psql -d bikemap -f speckle-wildlands.sql
