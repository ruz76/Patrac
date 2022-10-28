import fiona
import json
from shapely.geometry import shape
from shapely.geometry import mapping
import subprocess, os

def save_feature(path, geom_json):
    features = {
        "type": "FeatureCollection",
        "name": "region", "crs": {"type": "name", "properties": {"name": "urn:ogc:def:crs:EPSG::5514"}},
        "features": [{"type": "Feature", "properties": {"name": "null"}, "geometry": geom_json }]
    }
    with open(path, "w") as output:
        json.dump(features, output)

working_dir='/home/jencek/Documents/Projekty/PCR/github/Patrac/data/to_split_4'
data_dir = '/data/patracdata/kraje/zl'
shapes_dir = data_dir + '/vektor/ZABAGED/line_x/'
sektory = fiona.open(shapes_dir + 'merged_polygons_groupped.shp', 'r', encoding='utf-8')
count_all = 0
count_big = 0
for sector in sektory:
    geom = shape(sector['geometry'])
    # Bigger than 20 ha (1 ha = 10_000 square meters)
    if geom.area > 200000 and sector['properties']['typ'] != 'INTRAV':
        print(sector)
        count_big += 1
        print(geom.bounds[0])
        print(mapping(geom.envelope))
        save_feature(working_dir + "/cregion.geojson", mapping(geom.envelope))
        save_feature(working_dir + "/sektor.geojson", mapping(geom))
        with open("process.sh", "w") as output:
            output.write("bash export_vectors_zpm.sh " + data_dir + " " + str(geom.bounds[0]) + " " + str(geom.bounds[1]) + " " + str(geom.bounds[2]) + " " + str(geom.bounds[3]) + " " + working_dir + "\n")
            output.write("bash export_vectors_osm.sh " + str(geom.bounds[0]) + " " + str(geom.bounds[1]) + " " + str(geom.bounds[2]) + " " + str(geom.bounds[3]) + " " + working_dir + "\n")
            output.write("python3 split.py " + str(sector['properties']['id']) + "\n")
        subprocess.check_call("bash /home/jencek/Documents/Projekty/PCR/github/Patrac/src/main/python/split/process.sh", shell=True)
        print("DONE " + str(sector['properties']['id']))
    count_all += 1

print("Total: " + str(count_all) + " Big: " + str(count_big))
