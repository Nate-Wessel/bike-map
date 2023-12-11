DROP TABLE IF EXISTS syn_trips;

CREATE TABLE syn_trips (
	uid serial PRIMARY KEY,
	o_uid integer REFERENCES synthetic_trip_ods (uid),
	d_uid integer REFERENCES synthetic_trip_ods (uid),
	dist real CHECK (dist > -0),
	geom geometry(LINESTRING, 4326)
);

COPY syn_trips (o_uid, d_uid, dist) 
FROM '/home/nate/bike-map/demand/data/syn-trips.csv' CSV HEADER;

WITH sub AS (
	SELECT 
		trips.uid,
		ST_Transform(
			ST_MakeLine(origin.geom, destination.geom),
			4326
		) AS geom
	FROM syn_trips AS trips
	JOIN synthetic_trip_ods AS origin ON trips.o_uid = origin.uid
	JOIN synthetic_trip_ods AS destination ON trips.d_uid = destination.uid
	WHERE trips.geom IS NULL
)

UPDATE syn_trips SET geom = sub.geom 
FROM sub 
WHERE sub.uid = syn_trips.uid;
