# Bike Map

Almost all [bike maps](https://en.wikipedia.org/wiki/Bicycle_map) are actually maps for cars with some bike stuff just slapped on top. This project aims to turn a typical street map on its head, erasing all the familiar hierarchies (which developed around cars) and reinventing them based on the way cyclists would use the streets _as they exist today_. 

This is done using a realistic bicycle trip-planning application and data from OpenStreetMap. Hundreds of thousands of bicycle trips are simulated across the street network and edges which are used more often by our simulated cyclist are placed higher in the visual hierarchy of the resulting map. This is equivalent to the concept of betweenness in graph theory, or to an uncongested traffic simulation model in transport engineering. The difference from the later is that cycling is the only mode considered and the spatial distribution of trips need not be realistic. 

The code in this project is potentially applicable to anywhere in the world with decent OpenStreetMap data though since it is being developed in Toronto it will necessarily first try to tackle local scales and issues. 

Anyone interested in discussing the project, contributing, or raising an issue can join the conversation on Slack (civictechto.slack.com in the #bike-map channel) or leave an issue here. 

The project is further documented in the [project prospectus](prospectus/prospectus.pdf). You may also be interested to read a [paper about the predecessor to this map](http://cartographicperspectives.org/index.php/journal/article/view/1243/1414). 

## Code Dependencies
There are a few major software dependencies:
- QGIS
- PostgreSQL + PostGIS, hstore, pgRouting extensions
- [OSRM-backend](https://github.com/Project-OSRM/osrm-backend)
- Python3 (and `psycopg2`,`requests`,`json` and a few others) 
- osm2psql
