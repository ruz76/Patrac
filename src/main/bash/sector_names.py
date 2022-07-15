import psycopg2
import sys
from string import ascii_uppercase

conn_string="dbname='gdb' port='5432' user='postgres' password='mysecretpassword' host='localhost'"

def get_extent(kraj):
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        cursor.execute("SELECT ST_XMin(ST_SetSRID(ST_Extent(geom), 5514)) xmin, ST_YMin(ST_SetSRID(ST_Extent(geom), 5514)) ymin, ST_XMax(ST_SetSRID(ST_Extent(geom), 5514)) xmax, ST_YMax(ST_SetSRID(ST_Extent(geom), 5514)) ymax  FROM " + kraj + ".merged_polygons_grouped;")
        records = cursor.fetchall()
        if len(records) > 0:
            # The cell already exists
            xmin = records[0][0]
            ymin = records[0][1]
            xmax = records[0][2]
            ymax = records[0][3]
            xmin = xmin - 1000.0
            ymin = ymin - 1000.0
            xmax = xmax + 1000.0
            ymax = ymax + 1000.0
            dx = xmax - xmin
            dy = ymax - ymin
            print(xmin, ymin, xmax, ymax, dx, dy)
            edge = dx
            if dy > dx:
                edge = dy
            grid = edge / 26.0
            return grid, xmin, ymin
        else:
            print("Error " + kraj)
            return None
        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(e)

def process_cell(kraj, cellid, minx, miny, maxx, maxy):
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        query = "UPDATE " + kraj + ".merged_polygons_grouped p SET newid = CONCAT('" + cellid + "', s.overid) FROM (SELECT ROW_NUMBER() OVER(ORDER BY ST_XMin(geom), ST_YMin(geom)) overid, id FROM " + kraj +".merged_polygons_grouped WHERE ST_Within(geom, ST_MakeEnvelope(" + str(minx) + ", " + str(miny) + ", " + str(maxx) + ", " + str(maxy) + ", 5514)) OR ST_Intersects(geom, ST_MakeEnvelope(" + str(minx) + ", " + str(miny) + ", " + str(maxx) + ", " + str(maxy) + ", 5514))) s WHERE p.id = s.id;"
        # print(query)
        cursor.execute(query)
        conn.commit()
        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(e)

def process_grid(kraj):
    grid, origminx, origminy = get_extent(kraj)
    minx = origminx
    miny = origminy
    maxx = minx + grid
    maxy = miny + grid
    # print (grid, minx, miny, maxx, maxy)
    for i in ascii_uppercase:
        for j in ascii_uppercase:
            process_cell(kraj, i + "" + j, minx, miny, maxx, maxy)
            # print(grid, minx, miny, maxx, maxy)
            minx = maxx
            maxx = minx + grid
        miny = maxy
        maxy = miny + grid
        minx = origminx
        maxx = minx + grid

kraj = sys.argv[1]
process_grid(kraj)
