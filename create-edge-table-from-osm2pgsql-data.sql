DROP TABLE IF EXISTS gta_edges;
WITH sub AS (
	SELECT 
		t.id AS way_id,
		a.node_id,
		a.row_number,
		t.tags::hstore -> 'highway' AS highway,
		t.tags::hstore -> 'route' AS route, -- ferry
		t.tags::hstore -> 'service' AS service,
		t.tags::hstore -> 'footway' AS footway
	FROM 
		gta_ways AS t, 
		unnest(t.nodes) WITH ORDINALITY a(node_id, row_number)
	WHERE 
		t.tags::hstore -> 'highway' IS NOT NULL OR
		t.tags::hstore -> 'route' = 'ferry'
)
SELECT 
	s1.way_id,
	s1.highway,
	s1.route,
	s1.service,
	s1.footway,
	ARRAY[s1.node_id,s2.node_id] AS nodes
INTO gta_edges
FROM sub AS s1 JOIN sub AS s2
	ON s1.way_id = s2.way_id AND 
	s1.row_number = s2.row_number - 1;

-- sort the node ID's ascending, as is done in the script
UPDATE gta_edges SET nodes = ARRAY[nodes[2],nodes[1]]
WHERE nodes[1] > nodes[2];
CREATE INDEX ON gta_edges (nodes);
	
-- ADD COLUMNs to be used later
ALTER TABLE gta_edges
	ADD COLUMN bike_count integer DEFAULT 0, 
		
	ADD COLUMN n1geom geometry(POINT,4326), 
	ADD COLUMN n2geom geometry(POINT,4326),	
	ADD COLUMN edge geometry(LINESTRING,4326), 
	ADD COLUMN length real;

UPDATE gta_edges SET n1geom = ST_SetSRID(
	ST_MakePoint( lon/10000000.0, lat/10000000.0 ), -- lat/lon are stored as big integers
	4326
) FROM gta_nodes WHERE nodes[1] = id;
UPDATE gta_edges SET n2geom = ST_SetSRID(
	ST_MakePoint( lon/10000000.0, lat/10000000.0 ), -- lat/lon are stored as big integers
	4326
) FROM gta_nodes WHERE nodes[2] = id;
UPDATE gta_edges SET edge = ST_MakeLine(n1geom,n2geom);
UPDATE gta_edges SET length = ST_Length(edge);

-- save space
ALTER TABLE gta_edges 
	DROP COLUMN n1geom, 
	DROP COLUMN n2geom;

-- index and cluster for faster rendering
CREATE INDEX gta_edge_idx ON gta_edges USING GIST(edge);
CLUSTER gta_edges USING gta_edge_idx;
