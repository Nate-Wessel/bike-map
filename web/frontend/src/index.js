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
				"id":"streets",
				"source": "example_source",
				"source-layer":"street_edges",
				"type": "line",
				"paint": {
					"line-color": "black"
				}
			}
		]
		}
	})
	map.showTileBoundaries = true;
})

