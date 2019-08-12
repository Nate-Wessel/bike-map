WITH sub AS (
	SELECT 
		orig,
		dest,
		(ST_Dump(ST_GeneratePoints(oz.geom,total_trips))).geom AS ogeom,
		(ST_Dump(ST_GeneratePoints(dz.geom,total_trips))).geom AS dgeom
	FROM tts_trips AS t
	JOIN tts_2006_zones AS oz
		ON t.orig = oz.zone_id
	JOIN tts_2006_zones AS dz
		ON t.dest = dz.zone_id
	WHERE total_trips > 0
)
SELECT 
	orig, 
	dest, 
	ST_MakeLine(ogeom,dgeom)
INTO gen_trips
FROM sub;