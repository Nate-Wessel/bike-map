/*Synthesize O/D points along roads, to be used in trip generation */

DROP TABLE IF EXISTS syn_ods;

SELECT 
	osm_id,
	-- geom in local projection
	ST_Transform(ST_LineInterpolatePoint(way,random()),32617) AS geom,
	-- generate number of points in proportion to length +1
	generate_series(1,(ST_Length(ST_Transform(way,32617))/50)::int+1) AS way_uid
INTO syn_ods
FROM street_line
WHERE 
	highway IN ('primary','secondary','tertiary','residential','unclassified','cycleway') OR
	(highway = 'path' AND bicycle IN ('yes','designated'));

ALTER TABLE syn_ods ADD COLUMN uid serial PRIMARY KEY;

CREATE INDEX ON syn_ods USING GIST (geom);