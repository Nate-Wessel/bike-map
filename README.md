Almost all "bike maps" are actually maps for cars with some bike stuff slapped on top. This project aims to turn a typical street map on its head, erasing all the familiar street hierarchies (which developed around for cars) and reinventing them based on the way cyclists would use the streets as they exist today. 

This is done using a realistic bicycle trip-planning application and data from OpenStreetMap. Hundreds of thousands of bicycle trips are simulated across the street network and edges which are used more often by our simulated cyclist are placed higher in the visual hierarchy of the resulting map. This is equivalent to the concept of betweenness in graph theory, or to an uncongested traffic simulation model in transport engineering. The difference from the later is that cycling is the only mode considered and the spatial distribution of trips need not be realistic. 

The code in this project is potentially applicable to anywhere in the world with decent OpenStreetMap data though since it is being developed in Toronto it will necessarily try to represent the priorities and interests of a cyclist in that city. 

Anyone interested in discussing the project, contributing, or raising an issue can join the conversation on Slack (civictechto.slack.com in the #bike-map channel) or leave an issue here. 

The project is further documented in the [project prospectus](prospectus/prospectus.pdf). You may also be interested to read a [paper about the predecessor to this map](http://cartographicperspectives.org/index.php/journal/article/view/1243/1414). 

## TODO ##
There are several big domains of work that remain to be done, outlined and subdivided below. 

* Map simplification
    * Simplify split ways ([example](https://www.openstreetmap.org/#map=19/43.79249/-79.44591)) into single lines (all zoom levels). I'm working on finding these systematically with [Overpass](https://gist.github.com/Nate-Wessel/e7d72da7c7c12e00a472b41537334f8d). 
    * Use hierarchy in map reduction for low zoom levels. Research needed on appropriate algorithms/techniques.
    * Smooth and resample DEM. Alternatively convert to simplified contour polygons to reduce filesize of vector map derivatives. 
    * ... 

* OSM data verification and cleanup
    * Systematically verify/survey bicycle facilities
    * Once it is finalized [which landuse data](overpass/context.txt) will be included in the final map, these will need to be verified/refined in many cases - much of this data was imported a long time ago and hasn't been reviewed. 

* Route Selection
    * I need to decide on a representative route-selection strategy and ensure this is instantiated in the [OSRM bike.lua profile](osrm-profiles/default-bicycle.lua), or create such a profile. Another alternative is to define several strategies and let uses choose with some degree of interactive preference specification.

* Choice of Emphasis
    * The spatial distribution of simulated bike trips strongly effects the degree of emphasis placed on different parts of the map. I have not yet systematically explored what the desired effect should be e.g. between urban vs rural, or residential vs industrial/commercial areas. 

## Code Dependencies ##
There are a few major software dependencies:
- QGIS
- PostgreSQL + PostGIS and hstore extensions
- [OSRM-backend](https://github.com/Project-OSRM/osrm-backend)
- Python3 (and `psycopg2`,`requests`,`json` and a few others) 
- osm2psql
