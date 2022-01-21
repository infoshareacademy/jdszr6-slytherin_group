-----------------------------------------------------------------------------------------------
---------------------------------------NEW WORK------------------------------------------------


/*
select distinct 
zip_code ,
start_station_id ||'_'||end_station_id ,
to_char (tc.start_date, 'yyyy-mm') as year_month
from trip_csv tc 
where start_station_id ||'_'||end_station_id = '66_66'
order by to_char (tc.start_date, 'yyyy-mm')*/


drop view v_trip

--po³¹czenie tras_ID
create view v_trip as 
select * ,
start_station_id ||'_'|| end_station_id as trip_ID,
start_station_name ||' - '||end_station_name as trip_name,
count (*) over (partition by start_station_name ||' - '||end_station_name ) as trips_qty,
round(AVG(duration) over (partition by start_station_name ||' - '||end_station_name)/60,2) as avg_trips_duration
from v_trip_yearmonth
WHERE zip_code ='94107'

--iloœæ przejazdów per trasa w roko-mirsi¹cu top 10 tras
create view v_rank as
select 
*,
dense_rank() over (order by trips_qty desc) as ranking
from v_trip

drop view v_top10 

--wylistowane top 10 przejazdów w casie
select distinct 
trip_name,
year_month,
count(*) over (partition by year_month, trip_name)
from v_rank
where ranking <= 10

--widok z percentylami po przejazdach
create view v_percentile as
select 
trip_name,
percentile_disc(0.1) within group (order by duration) as per_01,
percentile_disc(0.5) within group (order by duration) as per_05,
percentile_disc(0.9) within group (order by duration) as per_09
from v_trip
group by trip_name

drop view v_percentile

--potrzebne dane do analizy
select
vt.id,
vt.duration,
vt.trip_name,
vt.year_month,
vt.trips_qty,
vt.avg_trips_duration,
vp.per_01,
vp.per_05,
vp.per_09,
zip_code ,
left(vt.year_month,4) as rok,
right(vt.year_month,2) as miesiac,
dense_rank() over (order by vt.trips_qty desc) as ranking
from v_trip vt
join v_percentile vp
on vt.trip_name = vp.trip_name

create view v_top_10_list as 
select distinct 
zip_code ,
trips_qty ,
vt.trip_name ,
dense_rank() over (order by vt.trips_qty desc) as ranking
from v_trip vt
join v_percentile vp
on vt.trip_name = vp.trip_name

drop view v_top_10_list

select distinct 
*
from v_top_10_list 
where ranking <=10
order by ranking

select
*,
count(*) over (order by vp.trip_name)
from v_trip vt
join v_percentile vp
on vt.trip_name = vp.trip_name
where vt.duration < vp.per_09 

select
*
from v_trip vt
join v_percentile vp
on vt.trip_name = vp.trip_name










