import fiona
from shapely.geometry import shape
from shapely.ops import linemerge
from shapely.ops import split
from shapely.geometry import mapping
from shapely.affinity import scale
from shapely.affinity import rotate
from shapely.affinity import translate
from shapely.geometry import LineString
import json, sys, os
import numpy as np

def get_usable_geoms(layer, sektor_buffer):
    geoms_to_use = []
    for feature in layer:
        geom = shape(feature["geometry"])
        if not geom.intersection(sektor_buffer).length == geom.length:
            geoms_to_use.append(geom)
    return geoms_to_use

def get_usable_geoms_on_geom(lines, sektor_buffer):
    geoms_to_use = []
    for line in lines:
        if not (line.intersection(sektor_buffer).length < 20 or line.intersection(sektor_buffer).length == line.length):
            geoms_to_use.append(line)
    return geoms_to_use

def azimuth(point1, point2):
    '''azimuth between 2 shapely points (interval 0 - 360)'''
    angle = np.arctan2(point2[0] - point1[0], point2[1]- point1[1])
    return np.degrees(angle) if angle >= 0 else np.degrees(angle) + 360

def get_angle_diff(segment1, segment2):
    angle1 = azimuth(segment1.coords[0], segment1.coords[1])
    angle2 = azimuth(segment2.coords[0], segment2.coords[1])
    # print(np.abs(angle2 - angle1))
    return np.abs(angle2 - angle1)

def get_lines_angle(line1, line2):
    first_segment_line1 = LineString(line1.coords[:2])
    last_segment_line1 = LineString(line1.coords[-2:])
    first_segment_line2 = LineString(line2.coords[:2])
    last_segment_line2 = LineString(line2.coords[-2:])
    if first_segment_line1.touches(first_segment_line2):
        return get_angle_diff(first_segment_line1, first_segment_line2)
    if first_segment_line1.touches(last_segment_line2):
        return get_angle_diff(first_segment_line1, last_segment_line2)
    if last_segment_line1.touches(first_segment_line2):
        return get_angle_diff(last_segment_line1, first_segment_line2)
    if last_segment_line1.touches(last_segment_line2):
        return get_angle_diff(last_segment_line1, last_segment_line2)
    return 0

def join_lines(lines, anglelimit):
    # print("Before join: " + str(len(lines)))
    lines_modified = []
    lines_merged_ids = []
    line1id = 0
    for line in lines:
        line2id = 0
        for line2 in lines:
            if line1id != line2id and line.touches(line2) and get_lines_angle(line, line2) < anglelimit and line2id not in lines_merged_ids:
                try:
                    merged_lines = linemerge([line, line2])
                    if merged_lines.geom_type == 'LineString':
                        lines_merged_ids.append(line2id)
                        lines_merged_ids.append(line1id)
                        lines_modified.append(merged_lines)
                except:
                    print(line)
                    print(line2)
            line2id += 1
        line1id += 1

    line1id = 0
    for line in lines:
        if line1id not in lines_merged_ids:
            lines_modified.append(line)
        line1id += 1

    # print("After join: " + str(len(lines_modified)))
    # print("****")
    return lines_modified

def write_to_geojson(geoms, shapes_dir, filename):
    features = []
    id = 0
    for geom in geoms:
        new_feature = {
            "type": "Feature",
            "properties": {
                "id": id,
            },
            "geometry": mapping(geom)
        }
        features.append(new_feature)
        id += 1
    collection = {
            "type": "FeatureCollection",
            "crs": {"type": "name", "properties": {"name": "urn:ogc:def:crs:EPSG::5514"}},
            "features": features
        }
    with open(shapes_dir + filename, "w") as f:
        f.write(json.dumps(collection))

def is_split_nice(splitted):
    nice_items_count = 0
    # print("SEKTOR AREA: " + str(sektor.area))
    for item in splitted:
        # print("SPLITTED ITEM AREA: " + str(item.area))
        # Bigger than 1 ha
        if item.area > 40000:
            nice_items_count += 1
    if nice_items_count == len(splitted) and len(splitted) > 1:
        return True
    else:
        return False

def split_sektor(sectors, line):
    output_sectors = []
    for sektor in sectors:
        if sektor.area > 200000:
            splitted = split(sektor, line)
            # print(len(splitted))
            nice = is_split_nice(splitted)
            # print(nice)
            if nice:
                for item in splitted:
                    output_sectors.append(item)
            else:
                output_sectors.append(sektor)
        else:
            output_sectors.append(sektor)
    return output_sectors

def split_sektor_by_lines(sectors, lines):
    for line in lines:
        sectors = split_sektor(sectors, line)
    # print(len(sectors))
    return sectors

def scale_lines(lines, extend_size):
    scaled_lines = []
    for line in lines:
        first_segment = LineString(line.coords[:2])
        factor_first = 1 + (extend_size / first_segment.length)
        last_segment = LineString(line.coords[-2:])
        factor_last = 1 + (extend_size / last_segment.length)
        scaled_last_segment = scale(last_segment, xfact=factor_last, yfact=factor_last, origin=last_segment.boundary[0])
        scaled_first_segment = scale(first_segment, xfact=factor_first, yfact=factor_first, origin=first_segment.boundary[1])
        new_line = LineString([*scaled_first_segment.coords, *line.coords[2:-2], *scaled_last_segment.coords])
        scaled_lines.append(new_line)
    return scaled_lines

def translate_lines(lines):
    translated = []
    for line in lines:
        new_line = translate(line, 0, 10, 0)
        translated.append(new_line)
        new_line = translate(line, 0, -10, 0)
        translated.append(new_line)
    return translated

def rotate_lines(lines, rotation, extend_size):
    rotated = []
    for line in lines:
        first_segment = LineString(line.coords[:2])
        factor_first = 1 + (extend_size / first_segment.length)
        last_segment = LineString(line.coords[-2:])
        factor_last = 1 + (extend_size / last_segment.length)
        scaled_last_segment = scale(last_segment, xfact=factor_last, yfact=factor_last, origin=last_segment.boundary[0])
        scaled_first_segment = scale(first_segment, xfact=factor_first, yfact=factor_first, origin=first_segment.boundary[1])
        scaled_last_segment = rotate(scaled_last_segment, rotation, origin=last_segment.boundary[0])
        scaled_first_segment = rotate(scaled_first_segment, rotation, origin=first_segment.boundary[1])
        new_line = LineString([*scaled_first_segment.coords, *line.coords[2:-2], *scaled_last_segment.coords])
        rotated.append(new_line)
    return rotated

def get_length_inside_sector(line, sector):
    intersection = sector.intersection(line)
    return intersection.length

def split_by_simple_lines(sector_to_split, lines_to_use, extend_size):
    # Join lines that touches each other and former simple linestring
    lines_before_join = lines_to_use.copy()
    # print(len(lines_before_join))
    attempts = 0
    diffzero = 0
    while True:
        lines_after_join = join_lines(lines_before_join, attempts + 1)
        attempts += 1
        if len(lines_before_join) == len(lines_before_join):
            diffzero += 1
        if attempts > 100 or diffzero > 5:
            break
        else:
            lines_before_join = lines_after_join
    extended_lines = lines_after_join
    # extended_lines = extend_by_moved_lines(lines_after_join)
    lines_after_split_by_sektor_boundary = split_lines_by_sector_boundary(extended_lines, sector_to_split.boundary)
    # print(len(lines_after_join))
    write_to_geojson(lines_after_split_by_sektor_boundary, shapes_dir, "lines_after_join.json")
    sectors = split_sektor_by_lines([sector_to_split], lines_after_split_by_sektor_boundary)
    write_to_geojson(sectors, shapes_dir, "sectors_after_first_split.json")
    scaled_lines = lines_after_join
    for a in range(1):
        scaled_lines = scale_lines(scaled_lines, extend_size)
        write_to_geojson(scaled_lines, shapes_dir, "lines_after_join_scaled_" + str(a) + ".json")

        sectors = split_sektor_by_lines(sectors, scaled_lines)
        write_to_geojson(sectors, shapes_dir, "sectors_after_split" + str(a) + ".json")

    return sectors

def extend_by_moved_lines(lines):
    output_lines = []
    for line in lines:
        moved = translate(line, 10, 0, 0)
        output_lines.append(moved)
        moved = translate(line, 0, 10, 0)
        output_lines.append(moved)
        moved = translate(line, -10, 0, 0)
        output_lines.append(moved)
        moved = translate(line, 0, -10, 0)
        output_lines.append(moved)
    return output_lines

def split_lines_by_sector_boundary(lines, sector_boundary):
    output_lines = []
    for line in lines:
        try:
            splitted = split(line, sector_boundary)
            for item in splitted:
                output_lines.append(item)
        except:
            a = 0 # just a placeholder
            # print('Input geometry segment overlaps with the splitter.')
    return output_lines

def get_lines_to_split_half_islands(sektor_geometry):
    lines_from_half_polygons = []
    sektor_buffer = sektor_geometry.buffer(-10)
    if type(sektor_buffer) is not list:
        return lines_from_half_polygons
    polygons = list(sektor_buffer)
    for polygon in polygons:
        polygon_back = polygon.buffer(11)
        boundary = polygon_back.boundary
        if boundary.type == 'MultiLineString':
            for line in boundary:
                lines_from_half_polygons.append(line)
        else:
            lines_from_half_polygons.append(boundary)
    return lines_from_half_polygons

def join_lines_recursively(lines_to_use, sectors):
    lines_before_join = lines_to_use.copy()
    # print(len(lines_before_join))
    print("Lines before join: " + str(len(lines_before_join)))
    attempts = 0
    diffzero = 0
    while True:
        lines_after_join = join_lines(lines_before_join, attempts + 1)
        attempts += 1
        if len(lines_before_join) == len(lines_before_join):
            diffzero += 1
        if attempts > 100 or diffzero > 5:
            break
        else:
            lines_before_join = lines_after_join
    print("Lines after join: " + str(len(lines_after_join)))
    for sector in sectors:
        lines_after_join = split_lines_by_sector_boundary(lines_after_join, sector.boundary)
    return lines_after_join

def split_by_single_longest_line(sectors, lines_after_join, longest_index, extend_limit):
    a = 0
    sectors_output = []
    for sector in sectors:
        if sector.area > 200000:
            sektor_buffer = sector.exterior.buffer(50)
            lines_to_use = get_usable_geoms_on_geom(lines_after_join, sektor_buffer)
            print("Lines for split: " + str(len(lines_to_use)))
            lines_to_use.sort(key=lambda x: get_length_inside_sector(x, sector), reverse=True)
            write_to_geojson(lines_to_use[0:1], shapes_dir, "lines_after_join_sorted_" + str(a) + "_0.json")
            a += 1
            # Split by longest line in the polygon
            attempts = 0
            splitted = False
            while True:
                attempts += 1
                outputs = None
                if (len(lines_to_use) > longest_index):
                    output = split_by_simple_lines(sector, [lines_to_use[longest_index]], (attempts) * extend_limit)
                    if len(output) > 1:
                        splitted = True
                if attempts > 1 or splitted:
                    if outputs is not None:
                        sectors_output += output
                    else:
                        sectors_output.append(sector)
                    break
        else:
            sectors_output.append(sector)
    return sectors_output

try:
    print("PROCESSING " + sys.argv[1])
    extend_limit = 100
    if sys.argv[2] in ["LPSTROM", "LPKROV"]:
        extend_limit = 50

    shapes_dir = '/home/jencek/Documents/Projekty/PCR/github/Patrac/data/to_split_5/'

    sektory = fiona.open(shapes_dir + 'sektor.geojson', 'r', encoding='utf-8')
    sektor_geometry = shape(shape(sektory[0]['geometry']))
    sektor_buffer = sektor_geometry.exterior.buffer(1)

    lines_to_split_half_islands = get_lines_to_split_half_islands(shape(sektory[0]['geometry']))

    osm_highway_track = fiona.open(shapes_dir + 'osm_highway_track.shp', 'r', encoding='utf-8')
    osm_highway_track_to_use = get_usable_geoms(osm_highway_track, sektor_buffer)
    lines_to_use = osm_highway_track_to_use + lines_to_split_half_islands

    with open("zpm.txt") as f:
        layers = f.readlines()
        for layer in layers:
            if os.path.exists(shapes_dir + layer.strip().lower() + '.shp'):
                layer_zpm = fiona.open(shapes_dir + layer.strip().lower() + '.shp', 'r', encoding='utf-8')
                layer_zpm_to_use = get_usable_geoms(layer_zpm, sektor_buffer)
                lines_to_use += layer_zpm_to_use

    sectors = split_by_simple_lines(sektor_geometry, lines_to_use, extend_limit)
    print("After first split: " + str(len(sectors)))

    # write_to_geojson(lines_to_use, shapes_dir, "lines_before_join.json")
    # lines_after_join = join_lines_recursively(lines_to_use, sectors)
    # write_to_geojson(lines_after_join, shapes_dir, "lines_after_join_second_use.json")

    for longest_index in range(4):
        for attempt in range(1):
            lines_after_join = join_lines_recursively(lines_to_use, sectors)
            sectors = split_by_single_longest_line(sectors, lines_after_join, longest_index, extend_limit)
            print("After " + str(attempt) + " split on index " + str(longest_index) + " : " + str(len(sectors)))

    for longest_index in range(4):
        for attempt in range(1):
            lines_after_join = join_lines_recursively(lines_to_use, sectors)
            rotated_1 = rotate_lines(lines_after_join, 5, 10)
            sectors = split_by_single_longest_line(sectors, rotated_1, longest_index, extend_limit)
            rotated_2 = rotate_lines(lines_after_join, 90, 10)
            sectors = split_by_single_longest_line(sectors, rotated_2, longest_index, extend_limit)
            print("After " + str(attempt) + " split by rotated on index " + str(longest_index) + " : " + str(len(sectors)))

    print("After last split: " + str(len(sectors)))
    write_to_geojson(sectors, shapes_dir, sys.argv[1] + ".json")

    # test_line = fiona.open(shapes_dir + 'test_line_full.shp', 'r', encoding='utf-8')
    # test_line_geometry = shape(shape(test_line[0]['geometry']))
    # splitted = split(sektor_geometry, test_line_geometry)
    # print(splitted)
except Exception as e:
    print("ERROR in processing: " + sys.argv[1])
    print(e)
