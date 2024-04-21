import fiona
import json
from shapely.geometry import shape
from shapely.geometry import mapping
import subprocess, os, sys

def save_feature(path, geom_json):
    features = {
        "type": "FeatureCollection",
        "name": "region", "crs": {"type": "name", "properties": {"name": "urn:ogc:def:crs:EPSG::5514"}},
        "features": [{"type": "Feature", "properties": {"name": "null"}, "geometry": geom_json }]
    }
    with open(path, "w") as output:
        json.dump(features, output)

def process_sector(geom, sector, full_extend, lines_name, output_name):
    extended_geom = geom.buffer(50)
    save_feature(working_dir + "/cregion.geojson", mapping(extended_geom.envelope))
    save_feature(working_dir + "/sektor.geojson", mapping(geom))
    with open(working_dir + "/process.sh", "w") as output:
        output.write("ogr2ogr " + working_dir + "/sektor.shp " + working_dir + "/sektor.geojson\n")
        output.write("bash export_vectors.sh " + data_dir + " " + str(extended_geom.bounds[0]) + " " + str(extended_geom.bounds[1]) + " " + str(extended_geom.bounds[2]) + " " + str(extended_geom.bounds[3]) + " " + working_dir + " " + lines_name + "\n")
        extend_limit = 5
        if full_extend:
            extend_limit = 100
            if sector['properties']['typ'] in ["LPSTROM", "LPKROV"]:
                extend_limit = 50
        output.write("bash split.sh " + str(sector['properties']['id']) + " " + working_dir + " " + str(extend_limit) + " " + sector['properties']['typ'] + " " + output_name + "\n")
    subprocess.check_call("bash " + working_dir + "/process.sh", shell=True)
    print("DONE " + str(sector['properties']['id']))


working_dir = sys.argv[1]
data_dir = sys.argv[2]
round = int(sys.argv[3])
shapes_dir = data_dir + '/vektor/ZABAGED/line_x/'

with open(working_dir + "/toprocess.txt") as tsp:
    toprocess = tsp.readlines()

if round == 0:
    sektory = fiona.open(shapes_dir + 'sectors_final.shp', 'r', encoding='utf-8')
else:
    sektory = fiona.open(working_dir + '/outputs/round' + str(round - 1) + '.shp', 'r', encoding='utf-8')

rounds = [
    {
        "lines_name": "lines_for_split_intrav.shp",
        "full_extend": False
    }
]

count_all = 0
count_big = 0
for sector in sektory:
    geom = shape(sector['geometry'])
    # lines_name = "lines_for_split_no_lespru_eleved.shp"
    if round == 0:
        # Bigger than 20 ha (1 ha = 10_000 square meters)
        # TODO Be careful this is new id as integer not the old one as string
        if geom.area > 200000 and sector['properties']['typ'] == 'INTRAV' and str(sector['properties']['id']) + "\n" in toprocess:
            # if geom.area > 200000 and sector['properties']['typ'] != 'INTRAV':
            count_big += 1
            process_sector(geom, sector, rounds[round]["full_extend"], rounds[round]["lines_name"], "round" + str(round) + ".shp")
    else:
        if geom.area > 200000:
            count_big += 1
            process_sector(geom, sector, rounds[round]["full_extend"], rounds[round]["lines_name"], "round" + str(round) + ".shp")
    count_all += 1

print("Total: " + str(count_all) + " Big: " + str(count_big))
