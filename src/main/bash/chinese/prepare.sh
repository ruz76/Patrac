sudo apt install postgresql-12-pgrouting osm2pgrouting osm2pgsql

create extension pgrouting;
create schema routing;

osm2pgsql -C 15000 -H localhost -d patrac -U patrac -W eustach.osm
alter table osm_cr.planet_osm_line set schema osm_cr;
alter table public.planet_osm_polygon set schema osm_cr;
alter table public.planet_osm_point set schema osm_cr;
alter table public.planet_osm_roads set schema osm_cr;
create index on osm_cr.planet_osm_line(tracktype);

#osm2pgrouting -f eustach.osm --schema routing --clean -d patrac -U patrac -W patrac
#osm2pgrouting pro velká data může skončit chybou, proto je nutné pustit pgr_nodeNetwork

drop table if exists routing.ways cascade;
create table routing.ways as select * from osm_cr.planet_osm_line where highway is not null and highway != '';
create index on routing.ways using gist(way);
SELECT pgr_nodeNetwork('routing.ways', 0.001, 'osm_id', 'way');
CREATE INDEX ON routing.ways_noded USING gist(way);
SELECT pgr_createTopology('routing.ways_noded', 0.001, 'way', 'id', 'source', 'target');

alter table routing.ways_noded add column grade int;
create index on routing.ways_noded(old_id);

update routing.ways_noded w set grade = substring(wwt.tracktype, 6, 1)::int from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and wwt.tracktype is not null and wwt.tracktype != 'unknown';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'asphalt';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'unpaved' and wwt.highway = 'track';
update routing.ways_noded w set grade = 2 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'unpaved' and wwt.highway = 'service';
update routing.ways_noded w set grade = 2 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'stone';
update routing.ways_noded w set grade = 1 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'sett';
update routing.ways_noded w set grade = 2 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'sand';
update routing.ways_noded w set grade = 2 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'pebblestone';
update routing.ways_noded w set grade = 2 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'paving_stones';
update routing.ways_noded w set grade = 1 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'paved';
update routing.ways_noded w set grade = 1 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'metal';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'ground';
update routing.ways_noded w set grade = 2 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'gravel';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'grass_paver';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'grass';
update routing.ways_noded w set grade = 2 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'fine_gravel';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'earth';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'dirt';
update routing.ways_noded w set grade = 3 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'concrete:plates:with_holes';
update routing.ways_noded w set grade = 3 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'concrete:plates';
update routing.ways_noded w set grade = 3 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'concrete:lanes';
update routing.ways_noded w set grade = 3 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'concrete';
update routing.ways_noded w set grade = 3 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'compacted';
update routing.ways_noded w set grade = 3 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.surface = 'cobblestone';
update routing.ways_noded w set grade = 2 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'service';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'steps';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'cycleway';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'footway';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'secondary';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'tertiary';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'secondary_link';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'living_street';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'primary';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'residential';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'track';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'motorway_link';
update routing.ways_noded w set grade = 0 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'motorway';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'unclassified';
update routing.ways_noded w set grade = 5 from osm_cr.planet_osm_line wwt where w.old_id = wwt.osm_id::int and w.grade is null and wwt.highway = 'path';
update routing.ways_noded w set grade = 6 where w.grade is null;

drop table if exists routing.chpostman_path;
drop table if exists routing.chpostman_path_export;
create table routing.chpostman_path as select id gid, '1' ord, '2024-01-01 00:00:00' ts, source, target from routing.ways_noded limit 1;
create table routing.chpostman_path_export as select id gid, '1' ord, '2024-01-01 00:00:00' ts, source source_path, target target_path, source source_way, target target_way, way the_geom from routing.ways_noded limit 1;

alter table routing.ways_noded add column x1 float;
alter table routing.ways_noded add column y1 float;
alter table routing.ways_noded add column x2 float;
alter table routing.ways_noded add column y2 float;
alter table routing.ways_noded add column length_m float;
alter table routing.ways_noded add column the_geom Geometry(LineString, 4326);

update routing.ways_noded set x1 = ST_X(ST_Transform(ST_StartPoint(way), 4326)), y1 = ST_Y(ST_Transform(ST_StartPoint(way), 4326)), x2 = ST_X(ST_Transform(ST_EndPoint(way), 4326)), y2 = ST_Y(ST_Transform(ST_EndPoint(way), 4326)), length_m = ST_Length(ST_Transform(way, 5514)), the_geom = ST_Transform(way, 4326);

drop view if exists routing.ways_simple;
create view routing.ways_simple as select the_geom, "source", target, length_m, id gid, x1, y1, x2, y2, grade from routing.ways_noded where source is not null and target is not null;
drop table if exists routing.ways_nodes;
create table routing.ways_nodes as select ST_SetSRID(ST_MakePoint(x1, y1), 4326), source, x1, y1 from routing.ways_simple;
drop table if exists routing.ways_for_sectors;
create table routing.ways_for_sectors as select w.id id, w.id gid from routing.ways_noded w limit 1;
drop table if exists routing.ways_for_sectors_export;
create table routing.ways_for_sectors_export as select "source", target,length_m, id gid, x1, y1, x2, y2 from routing.ways_noded limit 1;

CON_STRING="dbname=patrac user=patrac password=patrac host=localhost port=5432"
CON_STRING_OGR="host=localhost user=patrac dbname=patrac password=patrac"
ogr2ogr -nln ways -f "GPKG" "/data/patracdata/cr/line_search/data.gpkg" PG:"$CON_STRING_OGR" "routing.ways_simple" -overwrite
ogr2ogr -nln ways_nodes -f "GPKG" "/data/patracdata/cr/line_search/data.gpkg" PG:"$CON_STRING_OGR" "routing.ways_nodes" -overwrite
ogr2ogr -nln chpostman_path -f "GPKG" "/data/patracdata/cr/line_search/data.gpkg" PG:"$CON_STRING_OGR" "routing.chpostman_path" -overwrite
ogr2ogr -nln chpostman_path_export -f "GPKG" "/data/patracdata/cr/line_search/data.gpkg" PG:"$CON_STRING_OGR" "routing.chpostman_path_export" -overwrite
ogr2ogr -nln ways_for_sectors_export -f "GPKG" "/data/patracdata/cr/line_search/data.gpkg" PG:"$CON_STRING_OGR" "routing.ways_for_sectors_export" -overwrite
ogr2ogr -nln ways_for_sectors -f "GPKG" "/data/patracdata/cr/line_search/data.gpkg" PG:"$CON_STRING_OGR" "routing.ways_for_sectors" -overwrite


# Test only
create table routing.test_ka as
WITH bbox(geom) AS (
  VALUES (ST_Transform(ST_MakeEnvelope(12.071,49.856,13.311,50.507,4326),3857))
)
select * from routing.ways w, bbox where ST_Contains(bbox.geom,w.way);
# End test
