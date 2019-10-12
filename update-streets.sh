# UPDATE all data on all routable ways

cd ~/bike-map

# get new street data from the overpass API
wget -O data/streets.osm --post-file=overpass/ways.txt https://overpass-api.de/api/interpreter

# import way data into postGIS
osm2pgsql --slim --hstore-all --prefix street -d bikemap --style osm2pgsql/ways.style data/streets.osm

# create edges table
psql -d bikemap -f create-edge-table-from-osm2pgsql-data.sql

# process the data for OSRM-backend (but don't run that)
mkdir ~/scripts/osrm-backend/osm-data
cp data/streets.osm ~/scripts/osrm-backend/osm-data/bike.osm

cd ~/scripts/osrm-backend
# process OSRM for the bike profile
build/osrm-extract -p ~/bike-map/osrm-profiles/default-bicycle.lua osm-data/bike.osm
build/osrm-contract osm-data/bike.osrm
#build/osrm-routed osm-data/bike.osrm

# reuse the same data with the car profile
mv osm-data/bike.osm osm-data/car.osm
build/osrm-extract -p profiles/car.lua osm-data/car.osm
build/osrm-contract osm-data/car.osrm

# this is not needed for routing
rm osm-data/car.osm

# return to original folder
cd ~/bike-map
