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

DELETE FROM  sectors_pom a USING sectors_pom b WHERE a.gid < b.gid AND ST_Equals(a.geom, b.geom);
