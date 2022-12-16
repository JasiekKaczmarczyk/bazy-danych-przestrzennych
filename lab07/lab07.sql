-- 1 i 2 ze względu na długi czas przetwarzania wczytuję tylko kilka plików
-- raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d *.tif uk_250k | psql -d cw7 -h localhost -U postgres -p 5432

-- 3
create index idx_s_rast_gist on data_lakes using gist (ST_ConvexHull(rast));

select AddRasterConstraints('public'::name, 'data_lakes'::name,'rast'::name);

create table union_data as
select ST_Union(d.rast)
from data_lakes as d

-- 4 i 5 wczytanie danych national_parks

-- 6
create table data_lakes_clip as
select ST_Union(ST_Clip(a.rast, b.geom, true))
from data_lakes as a, national_parks as b
where b.id = 1 and ST_Intersects(b.geom,a.rast);

-- 7
create table out_clipped as
select lo_from_bytea(0, ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])) as loid
from data_lakes_clip;

select lo_export(loid, 'C:\Users\jkaczmarczyk\Documents\BDP\lab07\lake_district_clip.tif')
from out_clipped;

select lo_unlink(loid)
from out_clipped;

-- 8 i 9 wczytanie danych z sentinela

-- 10
create or replace function ndvi(
    value double precision [] [] [],
    pos integer [][],
    VARIADIC userargs text []
)
returns double precision as
$$
begin
    return (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value [1][1][1]);
$$
language 'plpgsql' immutable cost 1000;

create table ndvi as
with r as (
    select a.rid, ST_Clip(a.rast, b.geom,true) as rast
    from sentinel a, national_parks b
    where b.id = 1 and ST_Intersects(b.geom,a.rast)
)

select r.rid,ST_MapAlgebra(
    r.rast, ARRAY[1,4],
    'ndvi(double precision[], integer[],text[])'::regprocedure,
    '32BF'::text
) as rast
from r;

-- ndvi zwraca brak wyników
