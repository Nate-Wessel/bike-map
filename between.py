import psycopg2, requests, json, random, math

# connect to the census data DB
conn_string = ("host='localhost' dbname='bikemap' user='nate' password='mink'")
conn = psycopg2.connect(conn_string)
cursor = conn.cursor()

# get a list of origin -> destination trips to route
print("Getting trips")
cursor.execute("""
	SELECT 
		ST_X(ST_PointN(geom4326,1)) AS ox,
		ST_Y(ST_PointN(geom4326,1)) AS oy,
		ST_X(ST_PointN(geom4326,2)) AS dx,
		ST_Y(ST_PointN(geom4326,2)) AS dy
	FROM syn_all_trips
	WHERE orig <= 625 AND dest <= 625
	ORDER BY random()
	LIMIT 30000;
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
pairs = {}

count = 0

for trip in trips:
	Olon,Olat,Dlon,Dlat = trip
	# craft and send the request
	response = requests.get(
		'http://localhost:5000/route/v1/bicycle/'+
		str(Olon)+','+str(Olat)+';'+str(Dlon)+','+str(Dlat),
		params=options,
		timeout=10 # actually takes ~5ms
	)
	# parse the output
	j = json.loads(response.text)
	if j['code'] != 'Ok':
		print(response.text,'\n')
		continue
	# check that the trip isn't too long (e.g. opposite side of a river)	
	# or too short
	network_distance = j['routes'][0]['distance']
	#print(network_distance)
	# get the nodelist
	nodes = j['routes'][0]['legs'][0]['annotation']['nodes']

	# iterate over internode segments
	n1 = nodes[0]
	for i in range(1,len(nodes)):
		n2 = nodes[i]
		# order the nodes consistently
		if n1 < n2:
			key = str(n1)+'-'+str(n2)
		else: 
			key = str(n2)+'-'+str(n1)
		# increment the count
		if key not in pairs:
			pairs[key] = 1
		else:
			pairs[key] += 1
		# set for next iteration
		n1 = n2

	count += 1
	if count % 10 == 0:
		print( len(trips) - count, 'paths remaining' )

# write the output
outfile = open('nodepairs.csv','w+')
outfile.write('n1,n2,count\n')
for key,value in pairs.items():
	n1,n2 = key.split('-')
	outfile.write(n1+','+n2+','+str(value)+'\n')
outfile.close()

