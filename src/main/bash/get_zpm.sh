#!/usr/bin/env bash

. config/config.cfg

KRAJE="kh pa us lb pl ka st jc ms ol zl vy jm"
ZPM="2048 1024 512 256 128 64 32 16 8 4 2 1"
for i in $KRAJE; do
  echo $i;
  mkdir /data/patracdata/zpm/$i
  for j in $ZPM; do
    echo $j;
    echo "COPY (SELECT UPPER(obrazisf) FROM public.zpm_"$j"k WHERE ST_Within(geom, (SELECT ST_Buffer(geom, 20000) FROM public.nu3 WHERE pcrid = '"$i"')) OR ST_Intersects(geom, (SELECT ST_Buffer(geom, 20000) FROM public.nu3 WHERE pcrid = '"$i"'))) TO '/tmp/zpm.name';" > zpm.sql
    psql "$CON_STRING" -f zpm.sql
    cat /tmp/zpm.name > /data/patracdata/zpm/$i/$j
  done
done
