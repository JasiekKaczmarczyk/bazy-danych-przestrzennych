CREATE DATABASE lab2;
CREATE EXTENSION postgis;

CREATE TABLE buildings (id INTEGER PRIMARY KEY, geometry GEOMETRY, name VARCHAR);
CREATE TABLE roads (id INTEGER PRIMARY KEY, geometry GEOMETRY, name VARCHAR);
CREATE TABLE poi (id INTEGER PRIMARY KEY, geometry GEOMETRY, name VARCHAR);


INSERT INTO buildings(id, geometry, name) VALUES 
	(1, ST_GeomFromText('POLYGON ((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))', 0), 'BuildingA'),
	(2, ST_GeomFromText('POLYGON ((4 5, 6 5, 6 7, 4 7, 4 5))', 0), 'BuildingB'),
	(3, ST_GeomFromText('POLYGON ((3 6, 5 6, 5 8, 3 8, 3 6))', 0), 'BuildingC'),
	(4, ST_GeomFromText('POLYGON ((9 8, 10 8, 10 9, 9 9, 9 8))', 0), 'BuildingD'),
	(5, ST_GeomFromText('POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))', 0), 'BuildingF');


INSERT INTO roads(id, geometry, name) VALUES 
	(1, ST_GeomFromText('LINESTRING (0 4.5, 12 4.5)', 0),'RoadX'),
	(2, ST_GeomFromText('LINESTRING (7.5 0, 7.5 10.5)', 0),'RoadY');

INSERT INTO poi(id, geometry, name) VALUES
	(1, ST_GeomFromText('POINT(1 3.5)', 0), 'G'),
	(2, ST_GeomFromText('POINT(5.5 1.5)', 0), 'H'),
	(3, ST_GeomFromText('POINT(9.5 6)', 0), 'I'),
	(4, ST_GeomFromText('POINT(6.5 6)', 0), 'J'),
	(5, ST_GeomFromText('POINT(6 9.5)', 0), 'K');


-- a
select sum(st_length(geometry)) from roads

-- b
select geometry, st_area(geometry), st_perimeter(geometry) from buildings
where name='BuildingA'

-- c
select name, st_area(geometry) from buildings
order by name

-- d
select name, st_perimeter(geometry) perim from buildings
order by perim desc
limit 2

-- e
select st_distance(b.geometry, p.geometry)
from (select * from buildings where name='BuildingC') as b
cross join (select * from poi where name='K') as p

-- f
with C as(
	select geometry from buildings where name='BuildingC'
),
B as(
	select geometry from buildings where name='BuildingB'
)

select st_area(
	st_difference(
		C.geometry,
		st_buffer(
			B.geometry, 0.5
		)
	)
) from B cross join C

-- g
with X as(
	select geometry from roads where name='RoadX'
)

select name from buildings b cross join X x
where st_y(st_centroid(b.geometry)) > st_ymax(x.geometry)

-- h
select st_area(
	st_symdifference(
		geometry,
		st_geomfromtext('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')
	)
) 
from buildings
where name='BuildingC'
