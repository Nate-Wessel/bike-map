--DROP TABLE IF EXISTS syn_trips;
/*
CREATE TABLE syn_trips (
	uid serial PRIMARY KEY,
	o_uid integer,
	d_uid integer,
	dist real,
	ADD COLUMN geom geometry(LINESTRING,4326)
);
*/

COPY syn_trips (o_uid,d_uid,dist) 
FROM '/home/nate/bike-map/data/syn-trips.csv' CSV HEADER;

WITH sub AS (
	SELECT 
		t.uid,
		ST_MakeLine(o.geog::geometry,d.geog::geometry) AS geom
	FROM syn_trips AS t
	JOIN syn_ods AS o ON t.o_uid = o.uid
	JOIN syn_ods AS d ON t.d_uid = d.uid
	WHERE syn_trips.geom IS NULL
)
UPDATE syn_trips SET geom = sub.geom 
FROM sub 
WHERE sub.uid = syn_trips.uid;