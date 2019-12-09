from DBconnection import connection
from shapely.geometry import Point, LineString
from shapely.wkb import loads as loadWKB, dumps as dumpWKB

node_cursor = connection.cursor()
edge_cursor = connection.cursor()

# get a list of nodes (node_id) with degree = 2
node_cursor.execute("""
	WITH all_nodes AS (
		SELECT node_1 AS nid FROM street_edges WHERE render
		UNION ALL
		SELECT node_2 AS nid FROM street_edges WHERE render
	), node_degree AS (
		SELECT nid, COUNT(*) AS degree 
		FROM all_nodes GROUP BY nid
	) SELECT nid FROM node_degree WHERE degree = 2;
""")
nodes = node_cursor.fetchall()
print(len(nodes),'to check/merge')

keys = ['uid','way_id','node_1','node_2','name','f','r','geom']
for node_id, in nodes:
	# get the two edges connected to the given node
	edge_cursor.execute("""
		SELECT 
			uid, way_id, node_1, node_2, name, f, r, edge AS geom
		FROM street_edges 
		WHERE %(node_id)s IN (node_1,node_2) AND render;
	""",{ 'node_id': node_id } );
	assert edge_cursor.rowcount == 2
	# parse as dicts
	records = [ dict(zip(keys,edge)) for edge in edge_cursor.fetchall() ]
	r1,r2 = records[0],records[1]
	# only accept perfect matches
	if r1['way_id'] != r2['way_id']: continue
	if r1['f']      != r2['f']:      continue
	if r1['r']      != r2['r']:      continue
	print('\tmerging',(r1['name'] if r1['name']!=None else '-'),'on node',node_id)
	geom1 = loadWKB( r1['geom'], hex=True )
	geom2 = loadWKB( r2['geom'], hex=True )
	coords1, coords2 = geom1.coords, geom2.coords
	if r1['node_2'] == r2['node_1']: 
		n1,n2 = r1['node_1'],r2['node_2']
		newGeom = LineString( coords1[:len(coords1)-1] + list(coords2) )
	elif r2['node_2'] == r1['node_1']:
		n1,n2 = r2['node_1'],r1['node_2']
		newGeom = LineString( coords2[:len(coords2)-1] + list(coords1) )
	else: 
		print('as yet unhandled exception')
		# this is because edges currently all go the same way 
		# because they are from the same original way
		break 
	assert len(coords1)+len(coords2)-1 == len(newGeom.coords)
	# delete the first edge and update the second one
	edge_cursor.execute("""
		DELETE FROM street_edges WHERE uid = %(edge1id)s;
		UPDATE street_edges SET 
			node_1 = %(node_1)s, 
			node_2 = %(node_2)s,
			edge = ST_SetSRID(%(geom)s::geometry,3857),
			renovated = TRUE
		WHERE uid = %(edge2id)s;
	""",{
		'edge1id':r1['uid'],
		'edge2id':r2['uid'],
		'node_1': n1, 
		'node_2': n2,
		'geom': dumpWKB(newGeom,hex=True)
	})
	connection.commit()



