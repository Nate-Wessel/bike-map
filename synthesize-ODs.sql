/*Synthesize O/D points along roads, to be used in trip generation */

DROP TABLE IF EXISTS syn_ods;

SELECT 
	osm_id,
	ST_Transform(ST_LineInterpolatePoint(way,random()),4326)::geography AS geog,
	generate_series(1,(ST_Length(ST_Transform(way,4326)::geography)/100)::int+1) AS way_uid
INTO syn_ods
FROM gta_line
WHERE highway IN ('primary','secondary','tertiary','residential','unclassified','path','cycleway');

CREATE INDEX ON syn_ods USING GIST (geog);
