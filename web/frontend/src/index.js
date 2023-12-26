import * as maplibregl from 'maplibre-gl'
import * as pmtiles from 'pmtiles'

let protocol = new pmtiles.Protocol()
maplibregl.addProtocol("pmtiles", protocol.tile)

let url = 'http://localhost:8000/out.pmtiles';

const p = new pmtiles.PMTiles(url)

protocol.add(p)

// we first fetch the header so we can get the center lon, lat of the map.
p.getHeader().then( header => {
	const map = new maplibregl.Map({
		container: 'map',
		zoom: header.maxZoom - 2,
		center: [header.centerLon, header.centerLat],
		bearing: -17,
		style: {
			version:8,
			sources: {
				"example_source": {
					type: "vector",
					url: `pmtiles://${url}`
				}
			},
			layers: [
				{
					id: 'background',
					type: 'background',
					paint: {
						'background-color': '#ccc'
					}
				},
				{
					id:"streets-under",
					source: "example_source",
					'source-layer':"street_edges",
					type: "line",
					paint: {
						'line-color': "black",
						'line-width': ['ln', ['+',['get', 'f'],['get', 'r']]]
					},
					layout: {
						'line-join': 'round',
						'line-cap': 'round'
					}
				},
				{
					id:"streets-over",
					source: "example_source",
					'source-layer':"street_edges",
					type: "line",
					paint: {
						'line-color': [
							'step',
							['+',['get', 'f'],['get', 'r']],
							'white',
							100,
							'yellow',
							200,
							'red'
						],
						'line-width': ['/', ['ln', ['+',['get', 'f'],['get', 'r']]], 2]
					},
					layout: {
						'line-join': 'round',
						'line-cap': 'round'
					}
				}
			]
		}
	})
	map.showTileBoundaries = true;
})

