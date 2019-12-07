-- create temporary table with edge counts from python script
CREATE TEMP TABLE edge_counts (
	node_a bigint,
	node_b bigint,
	from_a smallint,
	from_b smallint
);
COPY edge_counts (node_a,node_b,from_a,from_b) 
FROM '/home/nate/bike-map/data/nodepairs.csv' CSV HEADER;

UPDATE street_edges SET f = 0 WHERE f != 0;
UPDATE street_edges SET r = 0 WHERE r != 0;

UPDATE street_edges SET f = from_a, r = from_b
FROM edge_counts
WHERE node_1 = node_a AND node_2 = node_b;

UPDATE street_edges SET r = from_a, f = from_b
FROM edge_counts
WHERE node_1 = node_b AND node_2 = node_a;

-- set edges to render, regardless of way type, if they are much used
UPDATE street_edges SET render = TRUE
WHERE render = FALSE AND f+r > 5;
