import fiona
from shapely.geometry import shape
from shapely.ops import linemerge
from shapely.ops import split
from shapely.geometry import mapping
from shapely.affinity import scale
from shapely.affinity import rotate
from shapely.affinity import translate
from shapely.geometry import LineString
import json

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
        if not line.intersection(sektor_buffer).length == line.length:
            geoms_to_use.append(line)
    return geoms_to_use

def join_lines(lines):
    # print("Before join: " + str(len(lines)))
    lines_modified = []
    lines_merged_ids = []
    line1id = 0
    for line in lines:
        line2id = 0
        for line2 in lines:
            if line1id != line2id and line.touches(line2) and line2id not in lines_merged_ids:
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
        if item.area > 50000:
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
        scaled_last_segment = rotate(scaled_last_segment, 5, origin=last_segment.boundary[0])
        scaled_first_segment = rotate(scaled_first_segment, 5, origin=first_segment.boundary[1])
        new_line = LineString([*scaled_first_segment.coords, *line.coords[2:-2], *scaled_last_segment.coords])
        scaled_lines.append(new_line)
        new_line = translate(new_line, 10, 0, 0)
        scaled_lines.append(new_line)
        new_line = translate(new_line, -10, 0, 0)
        scaled_lines.append(new_line)
        scaled_last_segment = rotate(scaled_last_segment, -10, origin=last_segment.boundary[0])
        scaled_first_segment = rotate(scaled_first_segment, -10, origin=first_segment.boundary[1])
        new_line = LineString([*scaled_first_segment.coords, *line.coords[2:-2], *scaled_last_segment.coords])
        scaled_lines.append(new_line)
        new_line = translate(new_line, 0, 10, 0)
        scaled_lines.append(new_line)
        new_line = translate(new_line, 0, -10, 0)
        scaled_lines.append(new_line)
    return scaled_lines

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
        lines_after_join = join_lines(lines_before_join)
        attempts += 1
        if len(lines_before_join) == len(lines_before_join):
            diffzero += 1
        if attempts > 100 or diffzero > 5:
            break
        else:
            lines_before_join = lines_after_join
    extended_lines = extend_by_moved_lines(lines_after_join)
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

    return [sectors, lines_after_split_by_sektor_boundary]

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
    attempts = 0
    diffzero = 0
    while True:
        lines_after_join = join_lines(lines_before_join)
        attempts += 1
        if len(lines_before_join) == len(lines_before_join):
            diffzero += 1
        if attempts > 100 or diffzero > 5:
            break
        else:
            lines_before_join = lines_after_join
    for sector in sectors:
        lines_after_join = split_lines_by_sector_boundary(lines_after_join, sector.boundary)
    return lines_after_join

def split_by_single_longest_line(sectors, lines_after_join, longest_index):
    a = 0
    sectors_output = []
    for sector in sectors:
        if sector.area > 200000:
            sektor_buffer = sector.exterior.buffer(50)
            lines_to_use = get_usable_geoms_on_geom(lines_after_join, sektor_buffer)
            lines_to_use.sort(key=lambda x: get_length_inside_sector(x, sector), reverse=True)
            write_to_geojson(lines_to_use[0:1], shapes_dir, "lines_after_join_sorted_" + str(a) + "_0.json")
            a += 1
            # Split by longest line in the polygon
            attempts = 0
            splitted = False
            while True:
                outputs = split_by_simple_lines(sector, [lines_to_use[longest_index]], (attempts + 1) * 100)
                attempts += 1
                if len(outputs[0]) > 1:
                    splitted = True
                if attempts > 10 or splitted:
                    sectors_output += outputs[0]
                    break
        else:
            sectors_output.append(sector)
    return sectors_output

shapes_dir = '/home/jencek/Documents/Projekty/PCR/github/Patrac/data/to_split/'

sektory = fiona.open(shapes_dir + 'sektor.shp', 'r', encoding='utf-8')
cesty = fiona.open(shapes_dir + 'cesty.shp', 'r', encoding='utf-8')
voda = fiona.open(shapes_dir + 'voda.shp', 'r', encoding='utf-8')
osm_highway_track = fiona.open(shapes_dir + 'osm_highway_track.shp', 'r', encoding='utf-8')

lines_to_split_half_islands = get_lines_to_split_half_islands(shape(sektory[0]['geometry']))

# print(sektor['geometry']['type'])
sektor_geometry = shape(shape(sektory[0]['geometry']))
sektor_buffer = sektor_geometry.exterior.buffer(1)
cesty_to_use = get_usable_geoms(cesty, sektor_buffer)
toky_to_use = get_usable_geoms(voda, sektor_buffer)
osm_highway_track_to_use = get_usable_geoms(osm_highway_track, sektor_buffer)
lines_to_use = cesty_to_use + toky_to_use + lines_to_split_half_islands + osm_highway_track_to_use
outputs = split_by_simple_lines(sektor_geometry, lines_to_use, 100)
sectors = outputs[0]
print("After first split: " + str(len(sectors)))

# write_to_geojson(lines_to_use, shapes_dir, "lines_before_join.json")
# lines_after_join = join_lines_recursively(lines_to_use, sectors)
# write_to_geojson(lines_after_join, shapes_dir, "lines_after_join_second_use.json")

for longest_index in range(4):
    for attempt in range(10):
        print("Lines before join: " + str(len(lines_to_use)))
        lines_after_join = join_lines_recursively(lines_to_use, sectors)
        print("Lines after join: " + str(len(lines_after_join)))
        sectors = split_by_single_longest_line(sectors, lines_after_join, longest_index)
        print("After " + str(attempt) + " split on index " + str(longest_index) + " : " + str(len(sectors)))

print("After last split: " + str(len(sectors)))
write_to_geojson(sectors, shapes_dir, "sectors_after_split_by_single_lines_0.json")

# test_line = fiona.open(shapes_dir + 'test_line_full.shp', 'r', encoding='utf-8')
# test_line_geometry = shape(shape(test_line[0]['geometry']))
# splitted = split(sektor_geometry, test_line_geometry)
# print(splitted)
