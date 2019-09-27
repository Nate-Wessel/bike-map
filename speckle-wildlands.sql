DROP TABLE IF EXISTS wild_points;

SELECT 
	osm_id, 
	-- this generates a multipoint type
	ST_GeneratePoints( p.way, (ST_Area(p.way)/100)::int + 1 ) AS geom
INTO wild_points
FROM context_polygon AS p
WHERE 
	--p.osm_id IN (201348958) 
	"natural" IN ('wood','wetland') OR landuse IN ('forest')