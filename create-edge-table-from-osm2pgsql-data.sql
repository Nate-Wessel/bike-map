DROP TABLE IF EXISTS gta_edges;

WITH way_nodes AS (
	SELECT 
		w.id AS way_id, 
		a.node_id, 
		a.row_number
	FROM gta_ways AS w, unnest(w.nodes) WITH ORDINALITY a(node_id, row_number)
	WHERE w.tags::hstore -> 'highway' IS NOT NULL
), ordered_way_nodes AS (
	SELECT 
		wn.way_id, wn.node_id, wn.row_number,
		ST_SetSRID(ST_MakePoint( n.lon/10000000.0, n.lat/10000000.0 ),4326) AS geom
	FROM way_nodes AS wn
	JOIN gta_nodes AS n ON wn.node_id = n.id
)
SELECT 
	n1.way_id,
	n1.node_id AS node_1,
	n2.node_id AS node_2,
	w.tags::hstore -> 'highway' AS highway,
	w.tags::hstore -> 'name' AS name,
	w.tags::hstore -> 'cycleway' AS cycleway,
	w.tags::hstore -> 'footway' AS footway,
	w.tags::hstore -> 'cycleway:left' AS "cycleway:left",
	w.tags::hstore -> 'cycleway:right' AS "cycleway:right",
	w.tags::hstore -> 'bicycle' AS bicycle,
	w.tags::hstore -> 'oneway' AS oneway,
	-- temporarily empty fields
	0::int AS f,
	0::int AS r,
	-- geometry
	ST_MakeLine(n1.geom,n2.geom) AS edge 
INTO gta_edges
FROM ordered_way_nodes AS n1 
JOIN ordered_way_nodes AS n2 ON 
	n1.way_id = n2.way_id AND 
	n1.row_number = n2.row_number - 1
JOIN gta_ways AS w ON
	w.id = n1.way_id;

-- index and cluster for faster rendering
CREATE INDEX gta_edge_idx ON gta_edges USING GIST(edge); -- for fast rendering
CLUSTER gta_edges USING gta_edge_idx;
-- for faster updating
CREATE INDEX ON gta_edges (node_1);
CREATE INDEX ON gta_edges (node_2);

