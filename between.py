import psycopg2, requests, json, random, math

# connect to the census data DB
conn_string = ("host='localhost' dbname='bikemap' user='nate' password='mink'")
conn = psycopg2.connect(conn_string)
cursor = conn.cursor()

# get a list of origin -> destination trips to route
print("Getting trips")
cursor.execute("""
	SELECT 
		ST_X(ST_PointN(geom,1)) AS ox,
		ST_Y(ST_PointN(geom,1)) AS oy,
		ST_X(ST_PointN(geom,2)) AS dx,
		ST_Y(ST_PointN(geom,2)) AS dy,
		row_number() OVER () AS row
	FROM syn_trips
	--LIMIT 500;
""")
trips = cursor.fetchall()
print('Starting...',len(trips),'trips')

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
	key = '{}-{}'.format(n1,n2) if n1 < n2 else '{}-{}'.format(n2,n1)
	# increment the count
	if key not in edges:
		edges[key] = {n1:1,n2:0}
	else:
		edges[key][n1] += 1

for trip in trips:
	Olon,Olat,Dlon,Dlat,row = trip
	# craft and send the request
	response = requests.get(
		'http://localhost:5000/route/v1/mode/'+
		str(Olon)+','+str(Olat)+';'+str(Dlon)+','+str(Dlat),
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
	if row % 100 == 0:
		print( len(trips) - row, 'paths remaining' )

# write the output
outfile = open('data/nodepairs.csv','w+')
outfile.write('nodeA,nodeB,fromA,fromB\n')
for i,edge in edges.items():
	n = list(edge.keys())
	outfile.write( '{},{},{},{}\n'.format(n[0],n[1],edge[n[0]],edge[n[1]]) )
outfile.close()

