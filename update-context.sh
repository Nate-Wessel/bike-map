# get new landuse/context data from the overpass API
wget -O bike-map/other-data/context.osm --post-file=bike-map/overpass/context.txt https://overpass-api.de/api/interpreter

# import data into postGIS, overwriting old data
osm2pgsql --slim --hstore-all --prefix context -d bikemap --style bike-map/osm2pgsql/context.style bike-map/other-data/context.osm
