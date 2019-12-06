from DBconnection import cursor

# get a list of nodes (node_id) with degree = 2
cursor.execute("""
	WITH streets AS (
		SELECT node_1, node_2
		FROM street_edges 
		WHERE 
			f+r > 5 OR
			(highway='path' AND bicycle='designated') OR
			highway in (
				'residential','unclassified',
				'tertiary','secondary','primary',
				'cycleway','pedestrian'
			)
	), nodes AS (
		SELECT node_1 AS nid FROM streets
		UNION ALL
		SELECT node_2 AS nid FROM streets
	), node_degree AS (
		SELECT nid, COUNT(*) AS degree 
		FROM nodes GROUP BY nid
	) SELECT nid FROM node_degree WHERE degree = 2
	LIMIT 1000;
""")
nodes = cursor.fetchall()
print(len(nodes),'to check/merge')

for node_id, in nodes:
	print('node_id =',node_id)
	cursor.execute("""
		SELECT  *
		FROM street_edges
		WHERE node_1 = %(node_id)s OR node_2 = %(node_id)s
		LIMIT 2;
	""",{'node_id':node_id});
	print(cursor.fetchall())
	break
