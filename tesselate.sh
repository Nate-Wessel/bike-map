#!/usr/bin/env bash

DBHOST="localhost"
DB="bikemap"


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DATA_DIR="$SCRIPT_DIR/data/pretiles"
WEB_DATA_DIR="$SCRIPT_DIR/web/frontend/dist"

echo $SCRIPT_DIR

# save spatial data as GeoJSON
ogr2ogr \
    -f GeoJSON $DATA_DIR/rail.geojson \
    "PG: dbname=$DB" \
    -sql "SELECT railway, service, ST_Transform(way,4326) AS geom FROM context_line WHERE railway IN ('rail','subway') AND tunnel IS NULL OR tunnel = 'no'"

ogr2ogr \
    -f GeoJSON $DATA_DIR/alley.geojson \
    "PG: dbname=$DB" \
    -sql "SELECT highway, service, ST_Transform(way,4326) AS geom FROM context_line WHERE highway = 'service' AND service = 'alley'"

# combine in tiles / --force makes it overwrite existing output
tippecanoe \
	--force \
	--minimum-zoom 11 --maximum-zoom 17 \
	-o $WEB_DATA_DIR/context.pmtiles \
	$DATA_DIR/rail.geojson \
	$DATA_DIR/alley.geojson

