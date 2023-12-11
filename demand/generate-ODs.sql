/*Synthesize O/D points along roads, to be used in trip generation */

DROP TABLE IF EXISTS synthetic_trip_ods;

CREATE TABLE synthetic_trip_ods (
	uid serial PRIMARY KEY,
	located_on_osm_id bigint,
	osm_id_uid smallint,
	geom geometry(POINT, 4326)
);

INSERT INTO synthetic_trip_ods (located_on_osm_id, osm_id_uid, geom)
SELECT
	osm_id AS located_on_osm_id,
	-- generate number of points in proportion to length +1
	-- roughly one every 50m
	generate_series(
		1,
		(ST_Length(ST_Transform(way, 2952)) / 50)::int + 1
	) AS osm_id_uid,
	ST_Transform(
		ST_LineInterpolatePoint(way, random()),
		4326
	) AS geom
FROM street_line
WHERE 
	highway IN (
		'primary',
		'secondary',
		'tertiary',
		'residential',
		'unclassified',
		'cycleway'
	)
	OR (
		highway = 'path'
		AND bicycle IN ('yes','designated')
	);

CREATE INDEX ON synthetic_trip_ods USING GIST (geom);

COMMENT ON TABLE synthetic_trip_ods IS 'random O/D points for trip generation';
