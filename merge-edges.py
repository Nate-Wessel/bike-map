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
		self.osm_way_id    = db_record.way_id
		self.name          = db_record.name
		self.node_1_id     = db_record.node_1
		self.node_2_id     = db_record.node_2
		self.forward_count = db_record.f
		self.reverse_count = db_record.r
		self.geometry      = loadWKB( db_record.geom, hex=True )

	def __eq__(self,other):
		# only accept perfect matches for now
		if self.osm_way_id    != other.osm_way_id:    return False
		if self.forward_count != other.forward_count: return False
		if self.reverse_count != other.reverse_count: return False
		return True

	def __repr__(self):
		return "Edge osm_id:{},db_uid:{}".format(self.osm_way_id, self.db_uid)

def mergeWKB(line1,line2):
	"""take two lines sharing a node in WKB format and return a single merged
	line with all nodes except the repeated one. The last coordinate of line1 
	should be identical to the first coordinate of line2."""
	# parse the geometries
	g1, g2 = line1, line2
	# make sure we have what we thhink we have
	assert len(g1.coords) >= 2 and len(g2.coords) >= 2
	assert g1.coords[-1] == g2.coords[0]
	# merge the lines
	newGeom = LineString( 
		g1.coords[:len(g1.coords)-1] + list(g2.coords) 
	)
	# check that lengths are identical within floating point tolerance
	assert abs((g1.length + g2.length)-newGeom.length) < 0.00001
	# return a binary geom string
	return dumpWKB(newGeom,hex=True)

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
print('merging edges')

for i, node_id, in enumerate(nodes):
	if i % 300 == 0:
		print('\rfinished checking',"{:.2%}".format(i/len(nodes)),'of',len(nodes),'nodes',end='\r')
	# get the two edges connected to the given node
	edge_cursor.execute("""
		SELECT 
			uid, way_id, node_1, node_2, name, f, r, edge AS geom
		FROM street_edges 
		WHERE %(node_id)s IN (node_1,node_2) AND render;
	""",{ 'node_id': node_id } );
	assert edge_cursor.rowcount == 2
	# parse as dicts
	edges = [ Edge(record) for record in edge_cursor.fetchall() ]
	e1,e2 = edges[0],edges[1]
	if e1 != e2: continue
	if e1.node_2_id == e2.node_1_id: 
		n1,n2 = e1.node_1_id,e2.node_2_id
		newGeom = mergeWKB(e1.geometry,e2.geometry)
	elif e2.node_2_id == e1.node_1_id:
		n1,n2 = e2.node_1_id,e1.node_2_id
		newGeom = mergeWKB(e2.geometry,e1.geometry)
	else: 
		print('as yet unhandled exception')
		print(e1,e2)
		# this is because edges should currently all go the same direction 
		# because they are from the same original way
		break 

	# delete the first edge and update the second one
	edge_cursor.execute("""
		UPDATE street_edges SET 
			node_1 = %(node_1)s, 
			node_2 = %(node_2)s,
			edge = ST_SetSRID(%(geom)s::geometry,3857),
			renovated = TRUE
		WHERE uid = %(edge1id)s;
		DELETE FROM street_edges WHERE uid = %(edge2id)s;
	""",{
		'edge1id':e1.db_uid,
		'edge2id':e2.db_uid,
		'node_1': n1, 
		'node_2': n2,
		'geom': newGeom
	})
	connection.commit()



