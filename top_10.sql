
/*
/*trasy w obrêbie SF*/
/*
create view v_best_trip as
select * ,
t.start_station_id || t.end_station_id as trip_ID,
t.start_station_name ||' - '||t.end_station_name as trip_name,
count (*) over (partition by t.start_station_id || t.end_station_id ) as trips_qty,
round(AVG(t.duration) over (partition by t.start_station_id || t.end_station_id)/60,2) as trips_duration
from trip t
WHERE t.zip_code like '94%'

drop view v_best_trip 

--top 10 wg czasu korzystania
select DISTINCT 
vb.trip_name,
vb.trip_ID,
trips_duration,
trips_qty
from v_best_trip vb
order by trips_duration DESC 
limit 10

--top 10 wg iloœci przejazdów
create view v_top_ten as
select DISTINCT 
vb.trip_name,
vb.trip_ID,
trips_duration,
trips_qty
from v_best_trip vb
order by trips_qty DESC 
limit 10


--miesi¹c rok w sqlite
select
t.start_date ,
CASE 
	when substring(start_date ,4,1) = '/' then substring(start_date ,5,4)
	when substring(start_date ,6,1) = '/' then substring(start_date ,7,4)
	else substring(start_date ,6,4)
end ||'-'||
case 
	when substring(t.start_date, 2,1) = '/' then '0'||substring(t.start_date, 1,1)
	else substring(t.start_date, 1,2)
end as year_month
from trip t 
*/
-----------------------------------------------------------------------------------------------
---------------------------------------NEW WORK------------------------------------------------
--widok tripu z rokmiesi¹c
create view v_trip_yearmonth as
select
*,
CASE 
	when substring(start_date ,4,1) = '/' then substring(start_date ,5,4)
	when substring(start_date ,6,1) = '/' then substring(start_date ,7,4)
	else substring(start_date ,6,4)
end ||'-'||
case 
	when substring(t.start_date, 2,1) = '/' then '0'||substring(t.start_date, 1,1)
	else substring(t.start_date, 1,2)
end as year_month
from trip t 

--po³¹czenie tras_ID
create view v_trip as 
select * ,
start_station_id || end_station_id as trip_ID,
start_station_name ||' - '||end_station_name as trip_name,
count (*) over (partition by start_station_id || end_station_id ) as trips_qty,
round(AVG(duration) over (partition by start_station_id || end_station_id)/60,2) as trips_duration
from v_trip_yearmonth
WHERE zip_code like '94%'

--iloœæ przejazdów per trasa w roko-mirsi¹cu top 10 tras
select DISTINCT 
t.year_month,
t.trip_ID,
t.trip_name,
substring(t.year_month,1,4) as 'year',
substring(t.year_month,6,2) as 'month',
count(*) over (partition by year_month||t.trip_ID) as month_trip_qty
from v_trip t
join v_top_ten tt
on tt.trip_ID = t.trip_ID





