cd ~/bike-map

# get new landuse/context data from the overpass API
wget -O other-data/context.osm --post-file=overpass/context.txt https://overpass-api.de/api/interpreter

# import data into postGIS, overwriting old data
osm2pgsql --slim --hstore-all --prefix context -d bikemap --style osm2pgsql/context.style other-data/context.osm

# clear out the OSM data once it's in PostGIS
rm other-data/context.osm
