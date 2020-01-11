from DBconnection import connection
from shapely.geometry import Point, LineString
from shapely.wkb import loads as loadWKB, dumps as dumpWKB
import psycopg2.extras

node_cursor = connection.cursor()
edge_cursor = connection.cursor(
	cursor_factory = psycopg2.extras.NamedTupleCursor 
)

class Edge(object):

	def __init__(self,db_record):
		self.db_uid        = db_record.uid
		self.osm_id        = db_record.way_id
		self.name          = db_record.name
		self.from_id       = db_record.node_1
		self.to_id         = db_record.node_2
		self.forward_count = db_record.f
		self.reverse_count = db_record.r
		self.geometry      = loadWKB( db_record.geom, hex=True )

	def __repr__(self):
		return "Edge osm_id:{}, db_uid:{}".format(self.osm_id, self.db_uid)

def mergeLine(line1,line2):
	"""take two lines sharing a node and return a single merged line with all 
	nodes except the repeated one."""
	l1c, l2c = line1.coords, line2.coords
	assert len(l1c) >= 2 and len(l2c) >= 2
	assert l1c[-1] == l2c[0]
	# try same-way combinations first
	if l1c[-1] == l2c[0]:
		newGeom = LineString( l1c[:len(l1c)-1] + list(l2c) )
	# check that lengths are correct within floating point tolerance
	assert abs((line1.length + line2.length)-newGeom.length) < 0.00001
	return newGeom

# get a list of nodes (node_id) with degree = 2
node_cursor.execute("""
	WITH all_nodes AS (
		SELECT node_1 AS nid FROM street_edges WHERE render
		UNION ALL
		SELECT node_2 AS nid FROM street_edges WHERE render
	), node_degree AS (
		SELECT nid, COUNT(*) AS degree 
		FROM all_nodes GROUP BY nid
	) SELECT nid FROM node_degree WHERE degree = 2 ORDER BY random();
""")

# for each potential node to merge on 
for merge_node_id, in node_cursor:
	if node_cursor.rownumber % 100 == 0: # output progress bar
		print(
			'\rfinished checking',
			"{:.2%}".format(node_cursor.rownumber/node_cursor.rowcount),
			'of',node_cursor.rowcount,
			'nodes',end='\r'
		)
	# get the two edges connected to the given node
	edge_cursor.execute("""
		SELECT uid, way_id, node_1, node_2, name, f, r, edge AS geom
		FROM street_edges 
		WHERE %(node_id)s IN (node_1,node_2) AND render;
	""",{ 'node_id': merge_node_id } );
	assert edge_cursor.rowcount == 2
	edgeA, edgeB = ( Edge(record) for record in edge_cursor.fetchall() )
		# only merge edges from the same way for now
	if edgeA.osm_id != edgeB.osm_id: continue 
	# we have a merge about to go down; check which edge goes where
	if edgeA.to_id == merge_node_id == edgeB.from_id:
		new_from_id = edgeA.from_id
		new_to_id   = edgeB.to_id
		newGeom     = mergeLine( edgeA.geometry, edgeB.geometry )
	elif edgeB.to_id == merge_node_id == edgeA.from_id:
		new_from_id = edgeB.from_id
		new_to_id   = edgeA.to_id 
		newGeom     = mergeLine(edgeB.geometry,edgeA.geometry)
	else: 
		print('\nas yet unhandled exception')
		print(merge_node_id, edgeA,edgeB)
		# this is because edges should currently all go the same direction 
		# because they are from the same original way
		continue
	# average (length weighted) forward and reverse values
	new_forward_count = round( (
			edgeA.forward_count * edgeA.geometry.length + 
			edgeB.forward_count * edgeB.geometry.length
		) / newGeom.length )
	new_reverse_count = round( (
			edgeA.reverse_count * edgeA.geometry.length + 
			edgeB.reverse_count * edgeB.geometry.length
		) / newGeom.length )
	# delete the first edge and update the second one
	edge_cursor.execute("""
		UPDATE street_edges SET 
			node_1 = %(node_1)s, 
			node_2 = %(node_2)s,
			r = %(r)s,
			f = %(f)s,
			edge = ST_SetSRID(%(geom)s::geometry,3857),
			renovated = TRUE
		WHERE uid = %(edge1id)s;
		DELETE FROM street_edges WHERE uid = %(edge2id)s;
	""",{
		'edge1id':edgeA.db_uid,
		'edge2id':edgeB.db_uid,
		'node_1': new_from_id,
		'node_2': new_to_id,
		'f':new_forward_count,
		'r':new_reverse_count,
		'geom': dumpWKB( newGeom, hex=True )
	})
	connection.commit()



