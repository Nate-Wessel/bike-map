import requests, json, random, math
from DBconnection import cursor
from alive_progress import alive_bar

# get a list of origin -> destination trips to route
print("Getting trips")
cursor.execute("""
	SELECT 
		ST_X(ST_PointN(geom,1)) AS ox,
		ST_Y(ST_PointN(geom,1)) AS oy,
		ST_X(ST_PointN(geom,2)) AS dx,
		ST_Y(ST_PointN(geom,2)) AS dy,
		row_number() OVER () AS row
	FROM syn_trips;
""")
trips = cursor.fetchall()

# OSRM API parameters
options = {
	'annotations':'true',
	'overview':'false',
	'steps':'false',
	'alternatives':'false'
}

# dict of edge counts keyed by osm id pairs, ascending order
edges = {}

def add_edge(node1,node2):
	global edges
	# key by unique node pairs
	key = f'{node1}-{node2}' if node1 < node2 else f'{node2}-{node1}'
	# increment the count
	if key not in edges:
		edges[key] = {n1:1,n2:0}
	else:
		edges[key][n1] += 1

with alive_bar(len(trips)) as bar:
	for trip in trips:
		Olon,Olat,Dlon,Dlat,row = trip
		# craft and send the request
		response = requests.get(
			f'http://localhost:5000/route/v1/bicycle/{Olon},{Olat};{Dlon},{Dlat}',
			params=options,
			timeout=10 # actually takes ~5ms
		)
		# parse the output
		j = json.loads(response.text)
		if j['code'] != 'Ok':
			print(response.text,'\n')
			continue
		# get the nodelist
		nodes = j['routes'][0]['legs'][0]['annotation']['nodes']

		# iterate over internode segments
		n1 = nodes[0]
		for i in range(1,len(nodes)):
			n2 = nodes[i]
			add_edge(n1,n2)
			# set for next iteration
			n1 = n2
		bar()

# write the output
outfile = open('data/nodepairs.csv','w+')
outfile.write('nodeA,nodeB,fromA,fromB\n')
for i,edge in edges.items():
	n = list(edge.keys())
	outfile.write( f'{n[0]},{n[1]},{edge[n[0]]},{edge[n[1]]}\n' )
outfile.close()

