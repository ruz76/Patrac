# Create list of nodes with associated segments
# Loop on nodes
# Use only nodes that have 2 associated segments
# For each node that has only 2 associated segments merge segments into one segment
# Replace original segments with new one on two nodes that should be connected to it
# Remove node from the list and start loop of the list from beginning
# There should not be any two associated segments node after these operations
# Maybe create two lists

import fiona
from shapely.geometry import shape, mapping, LineString, Point
from shapely.ops import linemerge
from copy import copy, deepcopy

def find_closest_points(line1, line2):
    """
    Finds the closest points between two lines and returns their coordinates.
    """
    coords1 = list(line1.coords)
    coords2 = list(line2.coords)
    min_distance = float("inf")
    closest_pair = None

    # Iterate over all pairs of points to find the minimum distance
    for p1 in coords1:
        for p2 in coords2:
            dist = Point(p1).distance(Point(p2))
            if dist < min_distance:
                min_distance = dist
                closest_pair = (p1, p2)

    return closest_pair

def merge_lines_smart(line1, line2):
    """
    Merges two lines by finding the closest points and connecting them in the right order.
    """
    # Find the closest points between the lines
    closest_p1, closest_p2 = find_closest_points(line1, line2)

    # Get the coordinates of the lines
    coords1 = list(line1.coords)
    coords2 = list(line2.coords)

    # Adjust the order or direction of the lines based on the closest points
    if closest_p1 == coords1[0]:  # First point of line1 is closest
        coords1 = coords1[::-1]
    if closest_p2 == coords2[-1]:  # Last point of line2 is closest
        coords2 = coords2[::-1]

    # Merge the coordinates without duplicating points
    merged_coords = coords1 + coords2

    return LineString(merged_coords)

# # Example lines
# line1 = LineString([(0, 0), (1, 1), (2, 2)])
# line2 = LineString([(2.1, 2.1), (3, 3), (4, 4)])  # Small gap
#
# # Merge the lines
# merged_line = merge_lines_smart(line1, line2)
#
# # Output
# print("Merged line:", merged_line)
#
# # Lines reversed
# line1 = LineString([(2, 2), (1, 1), (0, 0)])
# line2 = LineString([(4, 4), (3, 3), (2.1, 2.1)])  # Drobná mezera
#
# # merge
# merged_line = merge_lines_smart(line1, line2)
#
# # Result
# print(merged_line)
#
# exit(1)

def write_features_to_new_layer(features, input_file, source_layer, output_file, new_layer_name):
    """
    Write a list of features to a new layer in a GPKG file, copying schema and CRS
    from an existing layer in another file.

    Parameters:
    - features: List of features to write (each feature should be a dict with 'geometry' and 'properties').
    - input_file: Path to the existing GPKG file to copy schema and CRS from.
    - source_layer: Name of the layer in the input file to copy schema and CRS from.
    - output_file: Path to the GPKG file to write the features to.
    - new_layer_name: Name of the new layer to create in the output file.
    """
    # Open the source file to copy schema and CRS
    with fiona.open(input_file, layer=source_layer, mode="r") as src:
        schema = src.schema  # Copy schema
        crs = src.crs        # Copy CRS

        # Open the output file in write mode
        with fiona.open(
                output_file,
                mode="w",
                driver="GPKG",
                schema=schema,
                crs=crs,
                layer=new_layer_name,  # Use the new layer name
        ) as dst:
            # Write each feature to the new layer
            for feature in features:
                # Ensure that each feature has 'geometry' and 'properties'
                if "geometry" in feature and "properties" in feature:
                    geometry = feature["geometry"]

                    # If geometry is in the correct format, use it as is
                    if isinstance(geometry, dict) and 'type' in geometry and 'coordinates' in geometry:
                        # Fix coordinates if they are in a nested list (as in your example)
                        if isinstance(geometry['coordinates'][0], list):
                            # Convert list of lists into tuple of tuples
                            geometry['coordinates'] = [tuple(coord) for coord in geometry['coordinates']]

                    # Create a valid Shapely object using the geometry data
                    shapely_geom = shape(geometry)

                    # Write the feature to the output file
                    feature['geometry'] = mapping(shapely_geom)
                    dst.write(feature)

def write_features_to_new_layer_2(features, input_file, source_layer, output_file, new_layer_name):
    """
    Write a list of features to a new layer in a GPKG file, copying schema and CRS
    from an existing layer in another file.

    Parameters:
    - features: List of features to write (each feature should be a dict with 'geometry' and 'properties').
    - input_file: Path to the existing GPKG file to copy schema and CRS from.
    - source_layer: Name of the layer in the input file to copy schema and CRS from.
    - output_file: Path to the GPKG file to write the features to.
    - new_layer_name: Name of the new layer to create in the output file.
    """
    # Open the source file to copy schema and CRS
    with fiona.open(input_file, layer=source_layer, mode="r") as src:
        schema = src.schema  # Copy schema
        crs = src.crs        # Copy CRS

        # Open the output file in write mode
        with fiona.open(
                output_file,
                mode="w",
                driver="GPKG",
                schema=schema,
                crs=crs,
                layer=new_layer_name,  # Use the new layer name
        ) as dst:
            # Write each feature to the new layer
            try:
                for feature in features:
                    # geometry = feature["geometry"]
                    # geometry['coordinates'] = [list(coord) if isinstance(coord, tuple) else coord for coord in geometry['coordinates']]
                    # print(feature['geometry'])
                    dst.write(feature)
            except Exception as e:
                print(e)
                print(feature['geometry'])

def process_node_in_keep(key, node_A, node_B, nodes_keep, nodes_remove, merged_feature):
    if log_me:
        print("Keep Node A: " + str(node_A))
        # print(nodes_keep[node_A]['segments'])
        for segment in nodes_keep[node_A]['segments']:
            print("Segment: " + str(segment['properties']['source']) + " " + str(segment['properties']['target']))

    fixed_segments = []
    for segment in nodes_keep[node_A]['segments']:
        if segment['properties']['source'] != key and segment['properties']['target'] != key:
            fixed_segments.append(segment)

    # if log_me:
    #     print(fixed_segments)

    nodes_keep[node_A]['segments'] = fixed_segments
    nodes_keep[node_A]['segments'].append(merged_feature)
    if len(nodes_keep[node_A]['segments']) == 2:
        # If the updated node has two segments it has to be fixed
        # So we move it into node_removes and remove it from nodes_keep
        nodes_remove[node_A] = nodes_keep[node_A]
        del(nodes_keep[node_A])

def process_node_in_remove(key, node_A, node_B, nodes_keep, nodes_remove, merged_feature):
    if log_me:
        print("Remove Node A: " + str(node_A))
        # print(nodes_keep[node_A]['segments'])
        for segment in nodes_remove[node_A]['segments']:
            print("Segment: " + str(segment['properties']['source']) + " " + str(segment['properties']['target']))

    fixed_segments = []
    for segment in nodes_remove[node_A]['segments']:
        if segment['properties']['source'] != key and segment['properties']['target'] != key:
            fixed_segments.append(segment)

    if log_me:
        print(fixed_segments)

    nodes_remove[node_A]['segments'] = fixed_segments
    nodes_remove[node_A]['segments'].append(merged_feature)
    if len(nodes_remove[node_A]['segments']) != 2:
        # If the updated dones not have two segments it should not be fixed now
        # So we move it into nodes_keep and remove it from nodes_remove
        nodes_keep[node_A] = nodes_remove[node_A]
        del(nodes_remove[node_A])

nodes_keep = {}
nodes_remove = {}
# testing_gpkg = '/data/patracdata/tmp/chinese_testing/data_simple.gpkg'
testing_gpkg = '/data/patracdata/tmp/chinese_testing/data.gpkg'
# testing_gpkg = '/home/jencek/Documents/Projekty/Patrac/chinese_testing/data.gpkg'
way_to_test = [3733084, 715353]
way_to_test = [292130, 292129]
way_to_test = [351010, 56565]

with fiona.open(testing_gpkg, layer='ways') as layer:
    nodes = {}
    # Gets all nodes and associate the segments to it
    for feature in layer:
        if feature['properties']['source'] in nodes:
            nodes[feature['properties']['source']]['segments'].append(feature)
        else:
            nodes[feature['properties']['source']] = {
                "segments": [feature]
            }
        if feature['properties']['target'] in nodes:
            nodes[feature['properties']['target']]['segments'].append(feature)
        else:
            nodes[feature['properties']['target']] = {
                "segments": [feature]
            }
        # print(feature['properties']['source'])
        # print(feature)
        # line = shape(feature['geometry'])
        # print(line)
        # lines.append(line)

    # Splits into two lists, nodes_keep should be nodes that have one or more than two segments associated
    ways_count = 0
    for key in nodes:
        if len(nodes[key]['segments']) != 2:
            nodes_keep[key] = nodes[key]
        else:
            nodes_remove[key] = nodes[key]
        ways_count += len(nodes[key]['segments'])

    print(ways_count)
    print(len(nodes_keep))
    print(len(nodes_remove))

    for key in nodes_keep:
        if key in way_to_test:
            print("IT IS IN NODES KEEP")
            print(nodes_keep[key])

    # Loop the list to remove nodes
    while len(nodes_remove) > 0:
        key = next(iter(nodes_remove))
        print('\n***************************')
        print('Processing node: ' + str(key))
        if key in way_to_test:
            print("IT IS IN HERE NOW")
            print(nodes_remove[key])
        # print(key)
        node_1 = None
        node_2 = None
        segment_1 = nodes_remove[key]['segments'][0]
        segment_2 = nodes_remove[key]['segments'][1]
        merged_feature = deepcopy(segment_1)
        # TODO set x1, y1, x2, y2 based on source and target nodes
        if segment_1['properties']['source'] != key:
            node_1 = segment_1['properties']['source']
        else:
            node_1 = segment_1['properties']['target']
        if segment_2['properties']['source'] != key:
            node_2 = segment_2['properties']['source']
        else:
            node_2 = segment_2['properties']['target']

        merged_feature['properties']['source'] = node_1
        merged_feature['properties']['target'] = node_2
        merged_feature['properties']['length_m'] = segment_1['properties']['length_m'] + segment_2['properties']['length_m']
        merged_geom = merge_lines_smart(shape(segment_1["geometry"]), shape(segment_2["geometry"]))
        # merged_feature["geometry"] = merged_geom
        merged_feature["geometry"] = fiona.Geometry.from_dict(mapping(merged_geom))
        # print(merged_feature["geometry"])
        print("Merged Segments: " + str(node_1) + " " + str(node_2))

        log_me = True
        # if node_1 in way_to_test or node_2 in way_to_test:
        #     log_me = True

        if node_1 in nodes_keep:
            process_node_in_keep(key, node_1, node_2, nodes_keep, nodes_remove, merged_feature)
        elif node_1 in nodes_remove:
            process_node_in_remove(key, node_1, node_2, nodes_keep, nodes_remove, merged_feature)

        if node_2 in nodes_keep:
            process_node_in_keep(key, node_2, node_1, nodes_keep, nodes_remove, merged_feature)
        elif node_2 in nodes_remove:
            process_node_in_remove(key, node_2, node_1, nodes_keep, nodes_remove, merged_feature)

        del(nodes_remove[key])

for key in nodes_keep:
    if key in way_to_test:
        print("IT IS IN NODES KEEP AFTER SIMPLIFY")
        print(nodes_keep[key])

print(len(nodes_keep))
print(len(nodes_remove))
segments_to_export = {}

for key in nodes_keep:
    for segment in nodes_keep[key]['segments']:
        segment_key = str(segment['properties']['source']) + '_' + str(segment['properties']['target'])
        if segment_key in segments_to_export:
            exists_in_the_list = False
            for segment_in_export in segments_to_export[segment_key]:
                if segment_in_export['properties']['length_m'] == segment['properties']['length_m']:
                    exists_in_the_list = True
            if not exists_in_the_list:
                segments_to_export[segment_key].append(segment)
        else:
            segments_to_export[segment_key] = [segment]


segments_to_export_list = []
print(len(segments_to_export))
for key in segments_to_export:
    if key.find(str(way_to_test[0])) > -1 or key.find(str(way_to_test[1])) > -1:
        print(key)
    for segment in segments_to_export[key]:
        segments_to_export_list.append(segment)
        # print(segment['geometry'])

print(len(segments_to_export_list))

# ff = []
# with fiona.open(testing_gpkg, layer='ways') as layer:
#     for feature in layer:
#         # print(feature['geometry'])
#         ff.append(feature)

write_features_to_new_layer_2(segments_to_export_list, testing_gpkg, 'ways', testing_gpkg, 'ways_simplified')
