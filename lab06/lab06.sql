 -- 1
create database lab6;
create extension postgis;
create extension postgis_raster;
-- 2
create schema rasters;
create schema vectors;
create schema kaczmarczyk;

-- 3
select a.rast, b.municipality
from rasters.dem as a, vectors.porto_parishes as b
where ST_Intersects(a.rast, b.geom) and b.municipality ilike 'porto';

-- 4

select a.rast, b.municipality
from rasters.dem as a, vectors.porto_parishes as b
where ST_Intersects(a.rast, b.geom) and b.municipality ilike 'porto';

-- 5

select ST_Clip(a.rast, b.geom, true), b.municipality
from rasters.dem as a, vectors.porto_parishes as b
where ST_Intersects(a.rast, b.geom) and b.municipality like 'PORTO';

-- 6
select ST_Union(ST_Clip(a.rast, b.geom, true))
from rasters.dem as a, vectors.porto_parishes as b
where b.municipality ilike 'porto' and ST_Intersects(b.geom, a.rast);

-- 7

with r as (
  select rast
  from rasters.dem
  limit 1
)
select ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767) as rast
from vectors.porto_parishes as a, r
where a.municipality ilike 'porto';

-- 8
with r as (
  select rast
  from rasters.dem
  limit 1
)
select st_union(ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767)) as rast
from vectors.porto_parishes as a, r
where a.municipality ilike 'porto';

-- 9
with r as (
  select rast
  from rasters.dem
  limit 1
)
select st_tile(st_union(ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767)), 128, 128, true, -32767) as rast
from vectors.porto_parishes as a, r
where a.municipality ilike 'porto';

-- 10
select a.rid,
  (ST_Intersection(b.geom, a.rast)).geom,
  (ST_Intersection(b.geom, a.rast)).val
from rasters.landsat as a, vectors.porto_parishes as b
where b.parish ilike 'paranhos' and ST_Intersects(b.geom, a.rast);

-- 11

select a.rid,
  (ST_DumpAsPolygons(ST_Clip(a.rast, b.geom))).geom,
  (ST_DumpAsPolygons(ST_Clip(a.rast, b.geom))).val
from rasters.landsat as a, vectors.porto_parishes as b
where b.parish ilike 'paranhos' and ST_Intersects(b.geom, a.rast);

-- 12
create table kaczmarczyk.landsat_nir as
select rid, ST_Band(rast, 4) as rast
from rasters.landsat;

-- 13

create table kaczmarczyk.paranhos_dem as
select a.rid, ST_Clip(a.rast, b.geom, true) as rast
from rasters.dem as a, vectors.porto_parishes as b
where b.parish ilike 'paranhos' and ST_Intersects(b.geom, a.rast);

-- 14
create table kaczmarczyk.paranhos_slope as
select ST_Slope(a.rast, 1, '32BF', 'PERCENTAGE') as rast
from (
  with r as (select rast from rasters.dem limit 1
)
select st_tile(st_union(ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767)), 128, 128, true, -32767) as rast
from vectors.porto_parishes as a, r
where a.municipality ilike 'porto') as a;

-- 15

create table kaczmarczyk.paranhos_slope_reclass as
select ST_Reclass(a.rast, 1, ']0-15]:1, (15-30]:2, (30-9999:3', '32BF', 0)
from kaczmarczyk.paranhos_slope as a;

-- 16

select st_summarystats(a.rast) as stats
from kaczmarczyk.paranhos_dem as a;

-- 17
select st_summarystats(ST_Union(a.rast))
from kaczmarczyk.paranhos_dem as a;

-- 18
with t as (
  select st_summarystats(ST_Union(a.rast)) as stats
  from kaczmarczyk.paranhos_dem as a
)
select (stats).min, (stats).max, (stats).mean
from t;

-- 19
with t as (
  select b.parish as parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom, true))) as stats
  from rasters.dem as a, vectors.porto_parishes as b
  where b.municipality ilike 'porto' and ST_Intersects(b.geom, a.rast)
  group by b.parish
)
select parish, (stats).min, (stats).max, (stats).mean from t;

-- 20

select b.name, st_value(a.rast, (ST_Dump(b.geom)).geom)
from rasters.dem a, vectors.places as b
where ST_Intersects(a.rast, b.geom)
order by b.name;

-- 21
create table kaczmarczyk.tpi30 as
select ST_TPI(a.rast, 1) as rast
from rasters.dem a inner join vectors.porto_parishes b on st_intersects(a.rast, b.geom)
where b.municipality ilike 'porto';

-- 22

create table kaczmarczyk.porto_ndvi as
with r as (
  select a.rid, ST_Clip(a.rast, b.geom, true) as rast
  from rasters.landsat as a, vectors.porto_parishes as b
  where b.municipality ilike 'porto' and ST_Intersects(b.geom, a.rast)
)
select r.rid,
  ST_MapAlgebra(
          r.rast, 1,
          r.rast, 4,
          '([rast2.val] - [rast1.val]) / ([rast2.val] +
          [rast1.val])::float', '32BF'
      ) as rast
from r;

-- 23

create or replace function kaczmarczyk.ndvi(
    value double precision[][][],
    pos integer[][],
    VARIADIC userargs text[]
)
    RETURNS double precision as
$$
BEGIN
    RETURN (value[2][1][1] - value[1][1][1]) / (value[2][1][1] + value
        [1][1][1]);
END;
$$
    LANGUAGE 'plpgsql' IMMUTABLE
                       COST 1000;

create table kaczmarczyk.porto_ndvi2 as
with r as (select a.rid, ST_Clip(a.rast, b.geom, true) as rast
           from rasters.landsat as a,
                vectors.porto_parishes as b
           where b.municipality ilike 'porto'
             and ST_Intersects(b.geom, a.rast))
select r.rid,
       ST_MapAlgebra(
               r.rast, ARRAY [1,4],
               'kaczmarczyk.ndvi(double precision[],
                   integer[],text[])'::regprocedure,
               '32BF'::text
           ) as rast
from r;

-- 24
SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';

select ST_AsTiff(ST_Union(rast))
from kaczmarczyk.porto_ndvi;

-- 25

select ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 
'PREDICTOR=2', 'PZLEVEL=9'])
from kaczmarczyk.porto_ndvi;

-- 26

create table tmp_out as
select lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) as loid
from kaczmarczyk.porto_ndvi;
----------------------------------------------
select lo_export(loid, '/home/jasiek/projects/bdp/myraster.tiff')
from tmp_out;
----------------------------------------------
select lo_unlink(loid)
from tmp_out;
