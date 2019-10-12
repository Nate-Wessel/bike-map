--ALTER TABLE street_edges ADD COLUMN uid serial

--UPDATE temp_hw_edges SET dist = 1000 WHERE dist != 1000;

WITH RECURSIVE min_dist(uid,n1,n2,dist) AS (
	SELECT DISTINCT hw.uid, hw.node_1 AS n1, hw.node_2 AS n2, ST_Length(hw.edge::geography) AS dist 
	FROM street_edges AS hw
	JOIN street_edges AS st 
		ON hw.node_1 IN (st.node_1,st.node_2)
	WHERE 
		hw.highway IN ('motorway','motorway_link') AND
		st.highway NOT IN ('motorway','motorway_link','service')
UNION
	SELECT hw.uid, hw.node_1 AS n1, hw.node_2 AS n2, dist + ST_Length(hw.edge::geography) AS dist
	FROM street_edges AS hw 
	JOIN min_dist AS md
		ON md.n2 = hw.node_1
	WHERE 
		hw.highway IN ('motorway','motorway_link') AND
		dist < 1000
)
UPDATE temp_hw_edges SET dist = sub.dist
FROM ( SELECT uid, LEAST(MIN(dist),1000) AS dist FROM min_dist GROUP BY uid) AS sub
WHERE temp_hw_edges.uid = sub.uid;