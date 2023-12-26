import * as maplibregl from 'maplibre-gl'
import * as pmtiles from 'pmtiles'

let protocol = new pmtiles.Protocol()
maplibregl.addProtocol("pmtiles", protocol.tile)

const url = 'http://localhost:8000'

const streets = new pmtiles.PMTiles(`${url}/out.pmtiles`)
const context = new pmtiles.PMTiles(`${url}/context.pmtiles`)

protocol.add(streets)
protocol.add(context)

// we first fetch the header so we can get the center lon, lat of the map.
streets.getHeader().then( header => {
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
					url: `pmtiles://${url}/out.pmtiles`
				},
				"context": {
					type: "vector",
					url: `pmtiles://${url}/context.pmtiles`
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
					id: 'alleys',
					source: 'context',
					'source-layer': 'alley',
					type: 'line',
					paint: {
						'line-color': 'grey',
						'line-width': 0.5,
					}
				},
				{
					id: 'rail',
					source: 'context',
					'source-layer': 'rail',
					type: 'line',
					paint: {
						'line-color': 'grey',
						'line-width': 1,
						'line-dasharray': [5,5]
					},
					layout: {
						'line-join': 'round',
						'line-cap': 'round'
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

