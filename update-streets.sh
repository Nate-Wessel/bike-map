# UPDATE all data on all routable ways

cd ~/bike-map

# get new street data from the overpass API
wget -O data/gta.osm --post-file=overpass/ways.txt https://overpass-api.de/api/interpreter

# import way data into postGIS
osm2pgsql --slim --hstore-all --prefix gta -d bikemap --style osm2pgsql/ways.style data/gta.osm

# this makes a later query a little faster
psql -d bikemap -c "CREATE INDEX ON gta_nodes (id);"

# create edges table
psql -d bikemap -f create-edge-table-from-osm2pgsql-data.sql

# process the data for OSRM-backend (but don't run that)
mkdir ~/scripts/osrm-backend/osm-data
cp data/gta.osm ~/scripts/osrm-backend/osm-data/gta-bike.osm

cd ~/scripts/osrm-backend
# process OSRM for the bike profile
build/osrm-extract -p ~/bike-map/osrm-profiles/default-bicycle.lua osm-data/gta-bike.osm
build/osrm-contract osm-data/gta-bike.osrm
#build/osrm-routed osm-data/gta-bike.osrm

# reuse the same data with the car profile
mv osm-data/gta-bike.osm osm-data/gta-car.osm
build/osrm-extract -p profiles/car.lua osm-data/gta-car.osm
build/osrm-contract osm-data/gta-car.osrm

# reuse the same data with the foot profile
mv osm-data/gta-car.osm osm-data/gta-foot.osm
build/osrm-extract -p profiles/foot.lua osm-data/gta-foot.osm
build/osrm-contract osm-data/gta-foot.osrm

# this is not needed for routing
rm osm-data/gta-foot.osm

# return to original folder
cd ~/bike-map
