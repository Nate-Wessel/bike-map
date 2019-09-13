import psycopg2, requests, json
from random import random
from shapely import wkb
from shapely.wkb import dumps as dumpWKB
from shapely.geometry import Point, asShape

def random_point(zone_poly):
	"""return a random point within the passed polygon"""
	(min_x, min_y, max_x, max_y) = zone_poly.bounds
	rand_x = min_x + random() * (max_x - min_x)
	rand_y = min_y + random() * (max_y - min_y)
	point = Point(rand_x,rand_y)
	# if nt in the zone, try again
	while not point.within(zone_poly):
		rand_x = min_x + random() * (max_x - min_x)
		rand_y = min_y + random() * (max_y - min_y)
		point = Point(rand_x,rand_y)
	return point 

# connect to the census data DB
conn_string = ("host='localhost' dbname='bikemap' user='nate' password='mink'")
conn = psycopg2.connect(conn_string)
cursor1 = conn.cursor()
cursor2 = conn.cursor()
conn.autocommit = True

# get a list of TTS zones by ID with shapely geometries
print("Getting zones")
cursor1.execute("""
	SELECT 
		zone_id, 
		ST_Transform(geom,4326)
	FROM tts_2006_zones;
""")
zones = {}
for zone_id, geomwkb in cursor1.fetchall():
	zones[int(zone_id)] = wkb.loads(geomwkb, hex=True)

# OSRM API parameters
options = {
	'annotations':'true', 'overview':'full', 'geometries':'geojson',
	'steps':'false','alternatives':'false'
}

# get a list of trips to synthesize
print("Getting trips")
cursor1.execute("""
	SELECT 
		uid, orig_tts_zone, dest_tts_zone
	FROM syn_trips
	WHERE network_trip_geog IS NULL
	ORDER BY random()
	LIMIT 100000;
""")

# iterate over trips, sending requests to OSRM and storing results
for trip_uid, trip_orig, trip_dest in cursor1.fetchall():
	print(trip_uid, trip_orig, trip_dest)
	# define random points within orig and dest zones
	orig = random_point( zones[trip_orig] )
	dest = random_point( zones[trip_dest] )

	# create and send the request
	response = requests.get(
		'http://localhost:5000/route/v1/bicycle/'+
		str(orig.x)+','+str(orig.y)+';'+str(dest.x)+','+str(dest.y),
		params=options, timeout=1
	)
	# parse the output
	j = json.loads(response.text)
	if j['code'] != 'Ok':
		print(response.text,'\n')
		continue
	# good respone - now parse and store it
	results = {}
	results['uid'] = trip_uid
	results['network_distance'] =  j['routes'][0]['distance']
	results['orig_geom'] = dumpWKB(orig)
	results['dest_geom'] = dumpWKB(dest)
	results['path_geom'] = dumpWKB(asShape(j['routes'][0]['geometry']))
	
	
	cursor2.execute("""
		UPDATE syn_trips SET 
			network_trip_distance = %(network_distance)s,
			orig_geog = %(orig_geom)s::geography,
			dest_geog = %(dest_geom)s::geography,
			network_trip_geog = %(path_geom)s::geography
		WHERE uid = %(uid)s;
	""",results)

