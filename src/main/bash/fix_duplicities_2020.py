import psycopg2
import sys
from string import ascii_uppercase

conn_string="dbname='patrac' port='5432' user='patrac' password='patrac' host='localhost'"
table_name = "sektory_2020_pom_duplicities_2"

def completely_covered(aid):
    # The polygons in b geometry completely cover polygon in a geometry
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        cursor.execute("with u as (select ST_Union(bg) geom from " + table_name + " where aid = " + str(aid) + "), d as (select distinct ag from " + table_name + " where aid = " + str(aid) + ") select ST_area(ST_Difference(d.ag, St_Intersection(u.geom, d.ag))) from u, d;")
        records = cursor.fetchall()
        if len(records) > 0:
            # The cell already exists
            # print(records[0][0])
            if records[0][0] < 10:
                return True
            else:
                return False
        else:
            # print('BAD')
            return False
        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(e)

def append_covereging_ids(aid, covering_ids):
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        cursor.execute("select bid geom from " + table_name + " where aid = " + str(aid) + ";")
        records = cursor.fetchall()
        for record in records:
            covering_ids.append(record[0])
        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(e)
    return covering_ids

def test_me():
    # The polygons in b geometry completely cover polygon in a geometry
    covering_ids = []
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        cursor.execute("select aid from " + table_name + ";")
        records = cursor.fetchall()
        for record in records:
            if record[0] not in covering_ids:
                is_covered = completely_covered(record[0])
                if is_covered:
                    print(record[0])
                    append_covereging_ids(record[0], covering_ids)

        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(e)

def get_landuse(id):
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        cursor.execute("with d as (select distinct geom from sektory_2020_pom_3 where id = " + str(id) + ") select u.typ, ST_area(St_Intersection(u.geom, d.geom)) from sektory_2020_pom u, d where ST_Intersects(u.geom, d.geom) order by ST_area(St_Intersection(u.geom, d.geom)) desc limit 1;")
        records = cursor.fetchall()
        for record in records:
            print(str(id) + ';' + record[0] + ';' + str(record[1]))

        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(e)

def fix_landuse():
    # The polygons in b geometry completely cover polygon in a geometry
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        cursor.execute("select id from sektory_2020_pom_3 where typ is null;")
        records = cursor.fetchall()
        for record in records:
            get_landuse(record[0])

        cursor.close()
        conn.close()
    except psycopg2.Error as e:
        print(e)

# test_me()
fix_landuse()
