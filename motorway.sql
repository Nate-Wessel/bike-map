/*
Creates a table of motorway edges, with an attribute indicating how far away 
from the street network they are. 
*/

\echo Separating out the motorways

DROP TABLE IF EXISTS mw; -- MotorWays
-- select out just the motorways
CREATE TABLE mw AS 
SELECT 
	uid AS id,
	node_1 AS source, 
	node_2 AS target,
	ST_Length(edge) AS cost,
	edge AS geom,
	0::real AS dist_from 
FROM street_edges 
WHERE highway IN ('motorway','motorway_link');

-- all nodes to route to
CREATE TEMPORARY TABLE mw_nodes AS
SELECT DISTINCT unnest(array[source,target]) AS node FROM mw;

-- find nodes connecting motorways and streets on the map
-- i.e. all nodes to route from
DROP TABLE IF EXISTS connecting_nodes;
CREATE TABLE connecting_nodes AS 
SELECT 
	DISTINCT mw_nodes.node,
	NULL::geometry(POINT,4326) AS geom
FROM  mw_nodes
JOIN (
	SELECT DISTINCT unnest(array[node_1,node_2])AS node 
	FROM street_edges 
	WHERE render
) AS s
ON mw_nodes.node = s.node;

-- add node geometry for debugging
UPDATE connecting_nodes SET geom = ST_SetSRID(ST_MakePoint( 
	n.lon/10000000.0, 
	n.lat/10000000.0 
),4326)
FROM street_nodes AS n
WHERE n.id = connecting_nodes.node;

-- get the minimum directed distance to each segment and update

WITH sub AS (
	SELECT 
		end_vid AS node,
		MIN(agg_cost) AS min_cost
	FROM pgr_dijkstraCost(
		'SELECT id, source, target, cost FROM mw;',
		(SELECT ARRAY_AGG(node) FROM connecting_nodes),
		(SELECT ARRAY_AGG(node) FROM mw_nodes),
		TRUE
	)
	GROUP BY end_vid
), sub2 AS (
	SELECT 
		mw.id, mw.source, mw.target, 
		s1.min_cost, s2.min_cost,
		(s1.min_cost + s2.min_cost) / 2 AS avg_cost
	FROM mw 
	JOIN sub AS s1 ON mw.source = s1.node
	JOIN sub AS s2 ON mw.target = s2.node
	ORDER BY id
)
UPDATE mw set dist_from = avg_cost
FROM sub2 WHERE sub2.id = mw.id;

-- do it again but backwards
 -- TODO refactor to make this more elegant?
WITH sub AS (
	SELECT 
		end_vid AS node,
		MIN(agg_cost) AS min_cost
	FROM pgr_dijkstraCost(
		'SELECT id, target AS source, source AS target, cost FROM mw;',
		(SELECT ARRAY_AGG(node) FROM connecting_nodes),
		(SELECT ARRAY_AGG(node) FROM mw_nodes),
		TRUE
	)
	GROUP BY end_vid
), sub2 AS (
	SELECT 
		mw.id, mw.source, mw.target, 
		s1.min_cost, s2.min_cost,
		(s1.min_cost + s2.min_cost) / 2 AS avg_cost
	FROM mw 
	JOIN sub AS s1 ON mw.source = s1.node
	JOIN sub AS s2 ON mw.target = s2.node
	ORDER BY id
)
UPDATE mw set dist_from = avg_cost
FROM sub2 WHERE sub2.id = mw.id AND avg_cost < dist_from;



