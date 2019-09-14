/*Synthesize O/D points along roads, to be used in trip generation */

DROP TABLE IF EXISTS syn_points;

SELECT 
	osm_id,
	ST_LineInterpolatePoint(way,random()) AS geom,
	generate_series(1,(ST_Length(way::geography)/100)::int+1) AS way_uid
INTO syn_points
FROM gta_line
WHERE highway IN ('primary','secondary','tertiary','residential','unclassified','path','cycleway');

CREATE INDEX ON syn_points USING GIST (geom);