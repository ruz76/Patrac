#!/usr/bin/env bash

. config/config.cfg

KRAJ=$1

echo "DROP TABLE IF EXISTS $KRAJ.merged_polygons_grouped CASCADE;" > merged_polygons_grouped.sql
echo "CREATE TABLE $KRAJ.merged_polygons_grouped (geom Geometry('Multipolygon', 5514), id INT, typ VARCHAR(20), area FLOAT);" >> merged_polygons_grouped.sql
psql "$CON_STRING" -f merged_polygons_grouped.sql
