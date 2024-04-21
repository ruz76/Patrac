for i in {1..8}; do
  echo $i;
  ogr2ogr -append -update -f "PostgreSQL" -s_srs "EPSG:5514" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" /data/patracdata/kraje/cr/vektor/ZABAGED/line_x/split_intrav/$i/outputs/round0.shp -nln splitted_intravilans -lco GEOMETRY_NAME=geom -nlt PROMOTE_TO_MULTI
done

# Backup only
CREATE TABLE not_splitted_intravilans AS SELECT * FROM sectors_pom WHERE gid::varchar IN (SELECT id::varchar FROM splitted_intravilans);

# Remove splitted polygons
UPDATE sectors_pom SET status = 2 WHERE gid::varchar IN (SELECT id::varchar FROM splitted_intravilans);

# Insert splitted polygons
INSERT INTO sectors_pom (id, typ, geom, status) SELECT id::integer, typ, geom, '3'::smallint FROM splitted_intravilans;

1 = original
2 = intravilans for deleting
3 = intravilans splitted
6,7 = duplicities
8 = insiders

