DROP TABLE IF EXISTS wild_points;

SELECT 
	p.osm_id, 
	sub.geom
INTO wild_points
FROM context_polygon AS p
CROSS JOIN LATERAL (
	SELECT 
		osm_id,
		ST_SetSRID(ST_MakePoint(tmp.x,tmp.y), 3857) AS geom
	FROM (
		SELECT
			p.osm_id,
			random() * (ST_XMax(p.way)-ST_XMin(p.way)) + ST_XMin(p.way) AS x,
			random() * (ST_YMax(p.way)-ST_YMin(p.way)) + ST_YMin(p.way) AS y
		FROM generate_series( 0, ST_Area(ST_Envelope(p.way))::bigint/2000 )
	) AS tmp
) AS sub
WHERE 
	--p.osm_id IN (201348958) AND
	"natural" IN ('wood','wetland') OR landuse IN ('forest') AND
	p.osm_id = sub.osm_id AND
	ST_Intersects(p.way,sub.geom);