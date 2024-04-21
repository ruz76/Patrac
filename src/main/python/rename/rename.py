import fiona
from shapely.geometry import shape
from shapely.geometry import Point
import string
import json
from random import random

letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z']

def get_closest(point, points):
    distance = 1000000
    closets_point_position = -1
    position = 0
    for pt in points:
        # Not the same point
        if pt[0] != point[0]:
            cur_distance = pt[1].distance(point[1])
            if cur_distance < distance:
                distance = cur_distance
                closets_point_position = position
        position += 1
    return closets_point_position

def get_grid_cell_id(point):
    # LL -905000, -1228000
    # 20000 sirka - 25 položek
    # 3000 vyska - 98 položek
    # LL -905000, -1228000
    # UR -431724.3000,,-935236.9500
    minx = -905000
    dx = minx - point.x
    width = 20000
    letter_pos = abs(int(dx / width))
    miny = -1228000
    dy = miny - point.y
    height = 3000
    number_pos = abs(int(dy/height))
    return letters[letter_pos] + str(number_pos)

def get_grid():
    # LL -905000, -1228000
    # 20000 sirka - 25 položek
    # 3000 vyska - 98 položek
    # LL -905000, -1228000
    # UR -431724.3000,,-935236.9500
    grid = {}
    shift = 0
    for row in range(98):
        for col in range(25):
            cur_letter_pos = col - shift
            grid[letters[col] + str(row)] = {"letter": letters[cur_letter_pos], "number": 0, "number_intrav": 0}
        if shift < 20:
            shift += 4
        else:
            shift = 0
    with open("grid.json", "w") as out:
        out.write(json.dumps(grid))
    return grid

def process_test(features):
    rand = random()
    minx = -905000
    maxx = -431000
    miny = -1228000
    maxy = -935000
    x = minx + (maxx - minx) * rand
    y = miny + (maxy - miny) * rand
    all_features = []
    unique_features = set()
    for feature in features:
        centroid = shape(feature['geometry']).centroid
        # point = Point(x, y)
        if abs(centroid.x - x) < 7500 and abs(centroid.y - y) < 7500:
            all_features.append(feature['properties']['label'])
            unique_features.add(feature['properties']['label'])
    if len(all_features) != len(unique_features):
        print("ERROR: " + str(len(all_features)) + " " + str(len(unique_features)))
        print(str(x) + " " + str(y))
    else:
        print("TEST OK")

def process_sektory(grid):
    features = []
    s1_path = "/tmp/sektory_2020_pom.shp"
    sektory = fiona.open(s1_path)
    for feature in sektory:
        # print(str(feature))
        # print(dir(feature["properties"]))
        # print(str(feature["properties"]["id"]))
        # sid = feature['properties']['sid']
        centroid = shape(feature['geometry']).centroid
        grid_cell_id = get_grid_cell_id(centroid)
        if feature["properties"]["type"] != 'INTRAV':
            feature["properties"]["label"] = grid[grid_cell_id]["letter"] + str(grid[grid_cell_id]["number"])
            if grid[grid_cell_id]["number"] > 999:
                print("ERROR: Exceeded 1000 limit for sector " + grid[grid_cell_id]["letter"] + " " + str(grid[grid_cell_id]["number"]))
            grid[grid_cell_id]["number"] = grid[grid_cell_id]["number"] + 1
        else:
            feature["properties"]["label"] = 'I_' + grid[grid_cell_id]["letter"] + str(grid[grid_cell_id]["number_intrav"])
            if grid[grid_cell_id]["number_intrav"] > 999:
                print("ERROR: Exceeded 1000 limit for INTRAV sector " + grid[grid_cell_id]["letter"] + " " + str(grid[grid_cell_id]["number_intrav"]))
            grid[grid_cell_id]["number_intrav"] = grid[grid_cell_id]["number_intrav"] + 1
        features.append(feature)
        # print(str(feature["properties"]["id"]))
        # print(str(feature["properties"]["label"]))
        # print(str(feature["properties"].get("id")))
        # print(str(feature["properties"].get("label")))

    for i in range(20):
        try:
            process_test(features)
        except Exception as e:
            print(e)

    with open("sectors_pom_9_renamed.csv", "w") as out:
        for feature in features:
            out.write(str(feature["properties"]["id"]) + ';' + feature["properties"]["label"] + "\n")

# def process_sektory(grid):
#     # deprecated
#     features = []
#     s1_path = "/data/patracdata/cr/sektory_orig_NOINTRAV.shp"
#     s1_path = "/data/patracdata/kraje/zl/vektor/ZABAGED/line_x/merged_polygons_groupped_fixed_NOINTRAV.shp"
#     sektory = fiona.open(s1_path)
#     for feature in sektory:
#         # sid = feature['properties']['sid']
#         centroid = shape(feature['geometry']).centroid
#         grid_cell_id = get_grid_cell_id(centroid)
#         # print(grid_cell_id)
#         # sektory_named.append([sid, grid[grid_cell_id]["letter"] + str(grid[grid_cell_id]["number"])])
#         feature["properties"]["newid"] = grid[grid_cell_id]["letter"] + str(grid[grid_cell_id]["number"])
#         features.append(feature)
#         if grid[grid_cell_id]["number"] > 999:
#             print("ERROR: Exceeded 1000 limit for sector " + grid[grid_cell_id]["letter"])
#         grid[grid_cell_id]["number"] = grid[grid_cell_id]["number"] + 1
#
#     s2_path = "/data/patracdata/cr/sektory_orig_INTRAV.shp"
#     s2_path = "/data/patracdata/kraje/zl/vektor/ZABAGED/line_x/merged_polygons_groupped_fixed_INTRAV.shp"
#     sektory2 = fiona.open(s2_path)
#     for feature in sektory2:
#         centroid = shape(feature['geometry']).centroid
#         grid_cell_id = get_grid_cell_id(centroid)
#         feature["properties"]["newid"] = grid[grid_cell_id]["letter"] + str(grid[grid_cell_id]["number"])
#         features.append(feature)
#         if grid[grid_cell_id]["number"] > 999:
#             print("ERROR: Exceeded 1000 limit in INTRAV for sector " + grid[grid_cell_id]["letter"])
#         grid[grid_cell_id]["number"] = grid[grid_cell_id]["number"] + 1
#
#     for i in range(20):
#         try:
#             process_test(features)
#         except Exception as e:
#             print(e)
#     # with open("renamed.csv", "w") as out:
#     #     for sektor in sektory_named:
#     #         out.write(str(sektor[0]) + ";" + sektor[1] + "\n")
#     with open("renamed.geojson", "w") as out:
#         data = {
#             "type": "FeatureCollection",
#             "features":features
#         }
#         json.dump(data, out)

# def sektory_process():
#     # Deprecated
#     sektory_points = []
#     sektory_named = []
#     sektory = fiona.open("/data/patracdata/cr/sektory_orig.shp")
#     for feature in sektory:
#         sid = feature['properties']['sid']
#         centroid = shape(feature['geometry']).centroid
#         sektory_points.append([sid, centroid])
#
#     letters = string.ascii_uppercase
#     current_letter_pos = 0
#     current_number = 0
#     while len(sektory_points) > 1:
#         closest_position = get_closest(sektory_points[0], sektory_points)
#         sektory_named.append([sektory_points[closest_position][0], letters[current_letter_pos] + str(current_number)])
#         if current_letter_pos == 25:
#             current_letter_pos = 0
#             if current_number == 999:
#                 current_number = 0
#             else:
#                 current_number += 1
#         else:
#             current_letter_pos += 1
#         del sektory_points[closest_position]
#         if len(sektory_points) % 200 == 0:
#             print(len(sektory_points))
#
#     sektory_named.append([sektory_points[0][0], letters[current_letter_pos] + str(current_number)])
#     with open("renamed_all.csv", "w") as out:
#         for sektor in sektory_named:
#             out.write(str(sektor[0]) + ";" + sektor[1] + "\n")

grid = get_grid()
# print(grid)
process_sektory(grid)

