CREATE DATABASE lab3;
CREATE EXTENSION postgis;

-- 1
select geom from t2019_kar_buildings 
except 
select geom from t2018_kar_buildings

-- 2
with new_buildings as (
select geom from t2019_kar_buildings 
except 
select geom from t2018_kar_buildings
),
new_pois as (
select geom,type from t2019_kar_poi_table
except 
select geom, type from t2018_kar_poi_table
)

select count(np.geom), np.type
from new_pois np 
join new_buildings nb on st_contains(st_buffer(nb.geom, 0.005), np.geom)
group by np.type

-- 3
create table streets_reprojected as
(select * from t2019_kar_streets)

select * from streets_reprojected
select UpdateGeometrySRID('streets_reprojected','geom', 3068)

-- 4
create table input_points(id int, geom geometry, name varchar);

insert into input_points 
values 
(1, 'POINT(8.36093 49.03174)', 'A'),
(2, 'POINT(8.39876 49.00644)', 'B')

-- 5
select UpdateGeometrySRID('input_points','geom', 3068)	

-- 6
select UpdateGeometrySRID('t2019_kar_street_node','geom', 3068)	

with buffer as(
select st_buffer(st_MakeLine(geom),0.002)
from input_points)

select sn.geom
from t2019_kar_street_node sn
join buffer b on st_intersects(b.st_buffer, sn.geom)

-- 7
with sport_poi as (
select * 
from t2019_kar_poi_table
where type= 'Sporting Goods Store'
),
parks as (
select * 
from t2019_kar_land_use_a
where type like '%Park%'
)

select count(s.geom)
from sport_poi s 
join parks p on st_contains(st_buffer(p.geom, 0.003), s.geom)

-- 8
select st_intersection(r.geom, wl.geom)
into t2019_kar_bridges
from t2019_kar_railways r
join t2019_kar_water_lines wl on st_intersects(r.geom, wl.geom)

select * from t2019_kar_bridges









