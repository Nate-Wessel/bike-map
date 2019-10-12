DROP TABLE IF EXISTS contours_temp;

-- contours to update with new multigeometry
-- hole geometries to delete
SELECT 
	c1.gid AS gid_to_update,
	array_agg(c2.gid) AS gid_to_drop,
	ST_Difference(c1.geom,ST_Collect(c2.geom)) AS new_geom
INTO contours_temp
FROM contours AS c1 
JOIN contours AS c2 ON 
	c1.gid != c2.gid AND
	c1.level = c2.level AND
	ST_Contains(c1.geom,c2.geom)
GROUP BY c1.gid;

-- update geometries which need to get holes
UPDATE contours AS c SET geom = ST_Multi(ct.new_geom)
FROM contours_temp AS ct
WHERE c.gid = ct.gid_to_update;

-- drop the geometries that are the holes
DELETE FROM contours WHERE gid IN (SELECT unnest(gid_to_drop) FROM contours_temp);

DROP TABLE temp_contours;