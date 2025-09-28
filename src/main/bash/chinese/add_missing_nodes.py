import fiona
from shapely.geometry import shape, Point, mapping, LineString
import sys

# tolerance v ° (cca 1m)
TOLERANCE = 1.0 / 111320.0

gpkg_path = sys.argv[1]

# otevřeme vrstvu ways_nodes pro čtení i zápis
with fiona.open(gpkg_path, layer="ways_nodes", mode="r") as nodes:
    print(nodes.schema)
    # načteme existující body pro rychlé vyhledávání
    existing_nodes = [shape(feat["geometry"]) for feat in nodes]
    existing_props = [feat["properties"] for feat in nodes]

with fiona.open(gpkg_path, layer="ways_nodes", mode="a") as nodes:
    new_points = []
    # otevřeme ways pouze pro čtení
    with fiona.open(gpkg_path, layer="ways", mode="r") as ways:
        wpos = 0
        for way in ways:
            print(wpos)
            geom = shape(way["geometry"])
            if not isinstance(geom, LineString):
                continue

            start_pt = Point(geom.coords[0])
            end_pt = Point(geom.coords[-1])

            # kontrola blízkosti
            start_node = None
            start_node_props = None
            end_node = None
            end_node_props = None
            pos = 0
            for node in existing_nodes:
                if start_pt.distance(node) <= TOLERANCE:
                    start_node = node
                    start_node_props = existing_props[pos]
                if end_pt.distance(node) <= TOLERANCE:
                    end_node = node
                    end_node_props = existing_props[pos]
                pos += 1

            start_node_source = -1
            end_node_source = -1

            if start_node is None and end_node is None:
                start_node_source = way["properties"]["source"]
                end_node_source = way["properties"]["target"]

            if start_node is None and end_node is not None:
                if way["properties"]["source"] == end_node_props["source"]:
                    start_node_source = way["properties"]["target"]
                else:
                    start_node_source = way["properties"]["source"]

            if start_node is not None and end_node is None:
                if way["properties"]["source"] == start_node_props["source"]:
                    end_node_source = way["properties"]["target"]
                else:
                    end_node_source = way["properties"]["source"]

            # doplnění chybějících bodů
            if start_node is None:
                new_node = {
                    "geometry": mapping(start_pt),
                    "properties": {
                        "source": start_node_source,
                        "x1": start_pt.x,
                        "y1": start_pt.y
                    }
                }
                new_points.append(new_node)
                existing_nodes.append(start_pt)
                existing_props.append(new_node["properties"])

            if end_node is None:
                new_node = {
                    "geometry": mapping(end_pt),
                    "properties": {
                        "source": end_node_source,
                        "x1": start_pt.x,
                        "y1": start_pt.y
                    }
                }
                new_points.append(new_node)
                existing_nodes.append(end_pt)
                existing_props.append(new_node["properties"])

            wpos += 1

schema = {
    "geometry": "Point",
    "properties": {
        "source": "int",
        "x1": "float",
        "y1": "float"
    }
}

# zapíšeme do nové vrstvy
with fiona.open(
        sys.argv[2],
        layer="missing_nodes",
        mode="w",
        driver="GPKG",
        schema=schema,
        crs="EPSG:4326"
) as new_nodes_layer:
    for pt in new_points:
        new_nodes_layer.write(pt)
