/*Synthesize O/D points along roads, to be used in trip generation */

DROP TABLE IF EXISTS syn_ods;

SELECT 
	osm_id,
	-- geom in local projection
	ST_Transform(ST_LineInterpolatePoint(way,random()),26917) AS geom,
	-- generate number of points in proportion to length +1
	generate_series(1,(ST_Length(ST_Transform(way,26917))/100)::int+1) AS way_uid
INTO syn_ods
FROM gta_line
WHERE highway IN ('primary','secondary','tertiary','residential','unclassified','path','cycleway');

ALTER TABLE syn_ods ADD COLUMN uid serial PRIMARY KEY;

CREATE INDEX ON syn_ods USING GIST (geom);