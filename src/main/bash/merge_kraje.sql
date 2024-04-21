drop table if exists sectors_pom;
create table sectors_pom as select s.id, s.typ, s.geom from sectors_ka s join kraje k on (k.nk = 'KA' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_jc s join kraje k on (k.nk = 'JC' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_jm s join kraje k on (k.nk = 'JM' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_kh s join kraje k on (k.nk = 'KH' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_lb s join kraje k on (k.nk = 'LB' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_ms s join kraje k on (k.nk = 'MS' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_ol s join kraje k on (k.nk = 'OL' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_pa s join kraje k on (k.nk = 'PA' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_pl s join kraje k on (k.nk = 'PL' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_st s join kraje k on (k.nk = 'ST' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_us s join kraje k on (k.nk = 'US' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_vy s join kraje k on (k.nk = 'VY' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_zl s join kraje k on (k.nk = 'ZL' and st_intersects(s.geom, st_buffer(k.geom, 1000)));
insert into sectors_pom select s.id, s.typ, s.geom from sectors_st s join kraje k on (k.nk = 'HP' and st_intersects(s.geom, st_buffer(k.geom, 1000)));

create index on sectors_pom using gist(geom);
alter table sectors_pom add column gid serial;
update sectors_pom set geom = ST_MakeValid(geom);
DELETE FROM  sectors_pom a USING sectors_pom b WHERE a.gid < b.gid AND ST_Equals(a.geom, b.geom);
DELETE FROM sectors_pom WHERE ST_Area(geom) < 10;
DELETE FROM  sectors_pom a USING sectors_pom b WHERE a.gid < b.gid AND ST_Intersects(a.geom, b.geom) AND ((ST_Area(ST_Intersection(a.geom, b.geom)) / ST_Area(a.geom)) > 0.8) AND ((ST_Area(ST_Intersection(a.geom, b.geom)) / ST_Area(b.geom)) > 0.8);

-- Fix after bad big processing
insert into sectors_pom (id, typ, geom) select s.id, s.typ, ST_Multi(s.geom) from ka.merged_polygons s;
insert into sectors_pom (id, typ, geom) select s.id, s.typ, ST_Multi(s.geom) from pl.merged_polygons_groupped s;
insert into sectors_pom (id, typ, geom) select s.id, s.typ, ST_Multi(s.geom) from jc.merged_polygons_groupped s;
insert into sectors_pom (id, typ, geom) select s.id, s.typ, ST_Multi(s.geom) from jm.merged_polygons_groupped s;
insert into sectors_pom (id, typ, geom) select s.id, s.typ, ST_Multi(s.geom) from zl.merged_polygons_groupped s;

--Fix with holes
insert into sectors_pom (id, typ, geom, status) select s.fid, '', ST_Multi(s.geom), '4'::smallint from public.missing_areas_single s;

-- Remove duplicities
UPDATE sectors_pom SET geom = ST_MakeValid(geom);
DROP TABLE IF EXISTS sectors_pom_probably_duplicites;
CREATE TABLE sectors_pom_probably_duplicites AS SELECT a.gid agid, a.geom ageom, ST_Area(a.geom) aarea, b.gid bgid, b.geom bgeom, ST_Area(b.geom) barea FROM sectors_pom a, sectors_pom b WHERE a.gid < b.gid AND ST_Intersects(a.geom, b.geom) AND ((ST_Area(ST_Intersection(a.geom, b.geom)) / ST_Area(a.geom)) > 0.1) AND ((ST_Area(ST_Intersection(a.geom, b.geom)) / ST_Area(b.geom)) > 0.1);

update sectors_pom set status = 6 where gid in (select agid from sectors_pom_probably_duplicites);
update sectors_pom set status = 7 where gid in (select agid from sectors_pom_probably_duplicites);

create table sectors_pom_probably_duplicites_insiders as select s.gid, s.geom from sectors_pom s, sectors_pom_probably_duplicites_single d where s.status not in (6, 7) and ST_Intersects(s.geom, d.cgeom) and (ST_area(s.geom) - ST_Area(ST_Intersection(s.geom, d.cgeom))) < (ST_area(s.geom) / 10);
--ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $KRAJE_DIR/sectors_pom_probably_duplicites.shp PG:"$CON_STRING_OGR" "public.sectors_pom_probably_duplicites" -overwrite

update sectors_pom set status = 8 where gid in (select gid from sectors_pom_probably_duplicites_insiders);
create view sectors_pom_7 as select id, typ, gid, status, geom from sectors_pom where status not in (6, 7, 8);

