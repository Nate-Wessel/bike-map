﻿DROP TABLE IF EXISTS street_edges;

WITH way_nodes AS (
	SELECT 
		w.id AS way_id, 
		a.node_id, 
		a.row_number
	FROM street_ways AS w, unnest(w.nodes) WITH ORDINALITY a(node_id, row_number)
	WHERE 
		w.tags::hstore -> 'highway' IS NOT NULL AND
		w.tags::hstore -> 'area' IS NULL
), ordered_way_nodes AS (
	SELECT 
		wn.way_id, wn.node_id, wn.row_number,
		ST_SetSRID(ST_MakePoint(n.lon/10^7,n.lat/10^7),4326) AS geom
	FROM way_nodes AS wn
	JOIN street_nodes AS n ON wn.node_id = n.id
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
	w.tags::hstore -> 'cycleway:both' AS "cycleway:both",
	w.tags::hstore -> 'bicycle' AS bicycle,
	w.tags::hstore -> 'oneway' AS oneway,
	w.tags::hstore -> 'service' AS service,
	ST_MakeLine(n1.geom,n2.geom)::geography AS edge
INTO street_edges
FROM ordered_way_nodes AS n1 
JOIN ordered_way_nodes AS n2 ON 
	n1.way_id = n2.way_id AND 
	n1.row_number = n2.row_number - 1
JOIN street_ways AS w ON
	w.id = n1.way_id;

ALTER TABLE street_edges 
	ADD COLUMN uid serial PRIMARY KEY,
	ADD COLUMN render boolean DEFAULT TRUE,
	ADD COLUMN renovated boolean DEFAULT FALSE, -- just for testing
	ADD COLUMN f integer DEFAULT 0, -- forward count
	ADD COLUMN r integer DEFAULT 0; -- reverse count 

-- certain types of ways in the edge table should not render by default
UPDATE street_edges SET render = FALSE 
WHERE 
	highway IN (
		'footway','service','steps','corridor',
		'bus_stop','raceway', 'elevator',
		'motorway','motorway_link','proposed'
	) 
	OR 
	(highway = 'path' AND bicycle IS NULL OR bicycle NOT IN ('yes','designated'));

-- index for faster updates and rendering
CREATE INDEX ON street_edges USING GIST(edge);
CREATE INDEX ON street_edges (node_1);
CREATE INDEX ON street_edges (node_2);

