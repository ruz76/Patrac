import fiona
from shapely.geometry import shape
import subprocess, os, sys

def has_separable_half_islands(sector_geometry):
    sector_buffer = sector_geometry.buffer(-10)
    if sector_buffer.geom_type == 'MultiPolygon':
        polygons = list(sector_buffer)
        hasSeparableParts = 0
        for polygon in polygons:
            if polygon.area > 30000:
                hasSeparableParts += 1
        return hasSeparableParts > 1
    else:
        return False


sectors = fiona.open(sys.argv[1], 'r', encoding='utf-8')

ids = '('
for sector in sectors:
    geom = shape(sector['geometry'])
    if geom.area > 200000:
       if has_separable_half_islands(geom):
           ids += ", '" + str(sector['properties']['id']) + "'"

print(ids + ')')
