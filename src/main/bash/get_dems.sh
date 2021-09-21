#!/usr/bin/env bash

. config/config.cfg

echo $1
echo "COPY (SELECT field_2 FROM dmr4g_index WHERE ST_Within(geom, (SELECT ST_Buffer(geom, 20000) FROM public.nu3 WHERE nu3 = '"$1"')) OR ST_Intersects(geom, (SELECT ST_Buffer(geom, 20000) FROM public.nu3 WHERE nu3 = '"$1"'))) TO '/tmp/list.all';" > 1.sql
psql "$CON_STRING" -f 1.sql
