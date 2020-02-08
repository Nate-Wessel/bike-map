# UPDATE all data on all routable ways

cd ~/bike-map

# get new street data from the overpass API
wget -O data/streets.osm --post-file=overpass/ways.txt https://overpass-api.de/api/interpreter

# import way data into postGIS
osm2pgsql --slim --hstore-all --prefix street -d bikemap --style osm2pgsql/ways.style data/streets.osm

# create edges table
psql -d bikemap -f create-edge-table-from-osm2pgsql-data.sql

# create motorways table
psql -d bikemap -f motorway.sql

# process the data for OSRM-backend
mkdir ~/scripts/osrm-backend/osm-data
cp data/streets.osm ~/scripts/osrm-backend/osm-data/bike.osm

cd ~/scripts/osrm-backend

build/osrm-extract -p ~/bike-map/osrm-profiles/default-bicycle.lua osm-data/bike.osm
build/osrm-contract osm-data/bike.osrm
# this is not needed for routing
rm osm-data/bike.osm
# run the server in the background but be ready to kill it later
build/osrm-routed osm-data/bike.osrm & 
OSRMserverPID=$!

# return to original folder
cd ~/bike-map

# synthesize travel demand
psql -d bikemap -f demand/generate-ODs.sql
python3 demand/generate-trips.py # needs OSRM to be running
psql -d bikemap -f demand/create-trips-table.sql

# generate betweenness measures and add counts to edges
python3 between.py
psql -d bikemap -f update-edge-bike-counts.sql

# we can now kill the server
kill $OSRMserverPID

# merge needlessly split edges
python3 merge-edges.py
