import fiona
import json
from shapely.geometry import shape
from shapely.geometry import mapping
from shapely.affinity import scale
from shapely.affinity import rotate
from shapely.affinity import translate
from shapely.geometry import LineString
from shapely.ops import unary_union
from shapely.ops import split
import subprocess, os, sys
import math

def save_polygons(path, polygons, id):
    features = []
    for polygon in polygons:
        feature = {"type": "Feature", "properties": {"id": id}, "geometry": mapping(polygon) }
        if feature["geometry"]["type"] != "GeometryCollection":
            features.append(feature)
    features = {
        "type": "FeatureCollection",
        "name": "sectors_output", "crs": {"type": "name", "properties": {"name": "urn:ogc:def:crs:EPSG::5514"}},
        "features": features
    }
    with open(path, "w") as output:
        json.dump(features, output)

def get_group_id(intersections):
    area = 0
    id = 0
    index = 0
    for intersection in intersections:
        if intersection.area > area:
            area = intersection.area
            id = index
        index += 1
    return id

def split_bbox(bbox, line):
    splitted = split(bbox, line)
    parts = []
    if splitted[0].area > splitted[1].area:
        parts.append(splitted[0])
        parts.append(splitted[1])
    else:
        parts.append(splitted[1])
        parts.append(splitted[0])
    return parts

def has_neighbour(output_polygons, index):
    curidx = 0
    for polygon in output_polygons:
        if curidx != index and output_polygons[index].touches(polygon):
            return True
        curidx += 1
    return False

def has_neighbour_2(output_polygons, polygon_to_check):
    for polygon in output_polygons:
        if polygon_to_check.touches(polygon):
            return True
    return False

def reorganize_polygons(output_polygons, number_of_parts):
    for index in range(number_of_parts):
        if len(output_polygons[index]) > 1:
            curidx = 0
            items_to_remove = []
            for polygon in output_polygons[index]:
                if not has_neighbour(output_polygons[index], curidx):
                    # Seems that it is a polygon that does not belong to the group
                    # We go via all groups and find one where there is touch
                    for index2 in range(number_of_parts):
                        if has_neighbour_2(output_polygons[index2], polygon):
                            # Touches at least one polygon in the group
                            # We add it into the first group
                            output_polygons[index2].append(polygon)
                            # We log index of the item to remove from the origin group
                            items_to_remove.append(curidx)
                            break
                curidx += 1
            # We remove it from the origin group
            for item_to_remove in items_to_remove:
                del output_polygons[index][item_to_remove]

working_dir = sys.argv[1]
sector_id = sys.argv[2]

sektor = fiona.open(working_dir + '/s/sektor.shp', 'r', encoding='utf-8')
sektor_geom = shape(sektor[0]['geometry'])
sektor_area = sektor_geom.area
number_of_parts = math.ceil(sektor_area / 200000)

oriented_bbox_list = fiona.open(working_dir + '/oriented_bbox.shp', 'r', encoding='utf-8')
oriented_bbox = shape(oriented_bbox_list[0]['geometry'])
# print(dir(oriented_bbox))
# print(oriented_bbox.exterior.coords)
# print(oriented_bbox.exterior.parallel_offset(100, 'right'))
# oriented_bbox_rotated = rotate(oriented_bbox, -1 * oriented_bbox_list[0]['properties']['angle'], origin=oriented_bbox.centroid)
# print(oriented_bbox_list[0]['properties']['angle'])
oriented_bbox_rotated = rotate(oriented_bbox, oriented_bbox_list[0]['properties']['angle'], origin='centroid')
# oriented_bbox_rotated = rotate(oriented_bbox, -90, origin='centroid')
# print(oriented_bbox_rotated)
# print(oriented_bbox_rotated.bounds[0])

bbox_parts = []
print(number_of_parts)
segment_size = oriented_bbox_list[0]['properties']['height'] / number_of_parts
bbox_to_split = oriented_bbox_rotated
for part in range(number_of_parts - 1):
    print(part)
    line_for_split = LineString([(oriented_bbox_rotated.bounds[0] - 10, oriented_bbox_rotated.bounds[1] + (part + 1) * segment_size), (oriented_bbox_rotated.bounds[2] + 10, oriented_bbox_rotated.bounds[1] + (part + 1) * segment_size)])
    splitted_parts = split_bbox(bbox_to_split, line_for_split)
    if part >= (number_of_parts - 2):
        bbox_parts.append(rotate(splitted_parts[1], -1 * oriented_bbox_list[0]['properties']['angle'], origin=oriented_bbox.centroid))
        bbox_parts.append(rotate(splitted_parts[0], -1 * oriented_bbox_list[0]['properties']['angle'], origin=oriented_bbox.centroid))
    else:
        bbox_parts.append(rotate(splitted_parts[1], -1 * oriented_bbox_list[0]['properties']['angle'], origin=oriented_bbox.centroid))
        bbox_to_split = splitted_parts[0]

# split1_segment = LineString([(oriented_bbox_rotated.bounds[0] - 10, oriented_bbox_rotated.bounds[1] + segment_size), (oriented_bbox_rotated.bounds[2] + 10, oriented_bbox_rotated.bounds[1] + segment_size)])
# # print(split1_segment)
# splitted = split(oriented_bbox_rotated, split1_segment)
# # print(splitted)
# area = 0
# poly_to_split = None
# poly_to_keep = None
# if splitted[0].area > splitted[1].area:
#     poly_to_split = splitted[0]
#     poly_to_keep = splitted[1]
# else:
#     poly_to_split = splitted[1]
#     poly_to_keep = splitted[0]
# split1_segment = LineString([(oriented_bbox_rotated.bounds[0] - 10, oriented_bbox_rotated.bounds[1] + 2 * segment_size), (oriented_bbox_rotated.bounds[2] + 10, oriented_bbox_rotated.bounds[1] + 2 * segment_size)])
# print(split1_segment)
# splitted = split(poly_to_split, split1_segment)
# print(splitted)
# print(poly_to_keep)
# print(splitted[0])
# print(splitted[1])

# poly_to_keep_1 = rotate(poly_to_keep, -1 * oriented_bbox_list[0]['properties']['angle'], origin=oriented_bbox.centroid)
# poly_to_keep_2 = rotate(splitted[0], -1 * oriented_bbox_list[0]['properties']['angle'], origin=oriented_bbox.centroid)
# poly_to_keep_3 = rotate(splitted[1], -1 * oriented_bbox_list[0]['properties']['angle'], origin=oriented_bbox.centroid)
# print(poly_to_keep_1)
# print(poly_to_keep_2)
# print(poly_to_keep_3)

output_polygons = []
for index in range(number_of_parts):
    output_polygons.append([])
    print("BBOX PART")
    print(bbox_parts[index])

polygons_to_group = fiona.open(working_dir + '/clipped_cleaned.shp', 'r', encoding='utf-8')
for polygon in polygons_to_group:
    try:
        polygon_geom = shape(polygon['geometry'])
        intersections = []
        for index in range(number_of_parts):
            intersections.append(polygon_geom.intersection(bbox_parts[index]))
        output_polygons[get_group_id(intersections)].append(polygon_geom)
    except:
        print("BAD POLYGON")

# Not sure if this is necessary, but better do it more than once
for i in range(3):
   reorganize_polygons(output_polygons, number_of_parts)

groupped_polygons = []
for gr in output_polygons:
    groupped = unary_union(gr)
    groupped_polygons.append(groupped)
    # print(groupped)

save_polygons(working_dir + '/sectors_output.geojson', groupped_polygons, sector_id)

