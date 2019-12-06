import psycopg2

# connect to the database
connection = psycopg2.connect(
	"host='localhost' dbname='bikemap' user='nate' password='mink'"
)
cursor = connection.cursor()
