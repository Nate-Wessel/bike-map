-- create temporary table with edge counts from python script
DROP TABLE IF EXISTS edge_counts;
CREATE TABLE edge_counts (
	n1 bigint,
	n2 bigint,
	count integer
);
COPY edge_counts (n1,n2,count) 
FROM '/home/nate/bike-map/nodepairs.csv' CSV HEADER;

UPDATE gta_edges SET bike_count = count
FROM edge_counts
WHERE ARRAY[n1,n2] = nodes;

-- drop the temp table
DROP TABLE edge_counts;