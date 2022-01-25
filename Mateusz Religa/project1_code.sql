-- subskrybcje w czasie

select distinct 
v3.subscription_type ,
to_char (v3.start_date, 'yyyy-mm-dd') as year_month,
count(*) over (partition by v3.subscription_type, to_char (v3.start_date, 'yyyy-mm-dd')) as subscription_type_trips_count
from v3_trips_with_cities_zip_codes  v3
order by to_char (v3.start_date, 'yyyy-mm-dd')

--widok tripu z rokmiesi�c
create or replace view v_trip_yearmonth as
select *,
to_char (tc.start_date, 'yyyy-mm') as year_month
from v3_trips_with_cities_zip_codes tc 

drop view v_trip_yearmonth

--po��czenie tras_ID
create or replace view v_trip as 
select * ,
start_station_id ||'_'|| end_station_id as trip_ID,
start_station_name ||' - '||end_station_name as trip_name,
count (*) over (partition by start_station_name ||' - '||end_station_name )  as trips_qty,
round(AVG(duration) over (partition by start_station_name ||' - '||end_station_name)/60,2) as avg_trips_duration
from v_trip_yearmonth

WHERE zip_code in (select distinct 
					zip_code ::text
					from weather_csv wc 
					) --and start_station_id ||'_'|| end_station_id = '49_55' or start_station_id ||'_'|| end_station_id = '55_49' --do zmiany zipcode

drop view v_trip cascade 

--widok z percentylami po przejazdach
create or replace view v_percentile as
select 
trip_name,
percentile_disc(0.1) within group (order by duration) as per_01,
percentile_disc(0.5) within group (order by duration) as per_05,
percentile_disc(0.9) within group (order by duration) as per_09
from v_trip
group by trip_name

drop view v_percentile

create or replace view v_ranking as 
select distinct 
vt.trip_ID,
vt.trips_qty + vt2.trips_qty as All_qty,
dense_rank() over (order by vt.trips_qty + vt2.trips_qty desc) as ranking
from v_trip vt
join v_percentile vp
on vt.trip_name = vp.trip_name
join v_trip vt2 
on vt.trip_id = vt2.end_station_id ||'_'|| vt2.start_station_id

drop view v_ranking

-- generowanie top 10
select *
from v_ranking 
where ranking <=10

--wgrany z csv s�ownik na top10
select *
from top10dic tdc 

--dogranie s�ownika top 10 do trips by wyliczy� statystyki
--mo�na z niej wyci�ga� wszystkie dane z tabeli trips po top 10
select distinct 
td.trip_id_a ,
vt.year_month ,
sc.lat as lat_start_station,
sc.long as long_start_station,
sc2.lat as lat_end_station,
sc2.long as long_end_station,
avg(vt.duration) over (partition by td.trip_id_a) as trip_avg,
count(*) over (partition by td.trip_id_a, vt.year_month) as trip_qty,
dense_rank () over (partition by td.trip_id_a) as ranking
from v_trip vt 
join top10dic td 
on td.trip_id = vt.trip_id 
join station_csv sc 
on sc.id::text = left(td.trip_id_a,2)
join station_csv sc2 
on sc2.id::text = substring(td.trip_id_a from 4 for 2)

select *
from weather_csv wc 

--top10 w czasie 
select distinct 
td.trip_id_a ,
avg(vt.duration) over (partition by td.trip_id_a) as trip_avg,
count(*) over (partition by td.trip_id_a, vt.year_month) as trip_qty,
from v_trip vt 
join top10dic td 
on td.trip_id = vt.trip_id 
join station_csv sc 
on sc.id = vt.start_station_id 
join station_csv sc2 
on sc2.id = vt.end_station_id 

 
create view v_rank as
select distinct 
td.trip_id_a ,
count(*) over (partition by td.trip_id_a) as trip_qty	
from v_trip vt 
join top10dic td 
on td.trip_id = vt.trip_id 


--fianlana tabela z po��czeniem s�ownika, latitude, long, trip qty, ranking
select distinct
td.trip_id_a ,
vt.year_month ,
count(*) over (partition by td.trip_id_a, vt.year_month) as trip_qty,
dense_rank () over (order by trip_qty desc) as ranking,
avg (vt.duration) over (partition by td.trip_id_a, vt.year_month )/60 as avg_trips_duration_per_month, 
avg (vt.duration) over (partition by td.trip_id_a)/60 as avg_trips_duration_all, 
sc.lat as lat_start_station,
sc.long as long_start_station,
sc2.lat as lat_end_station,
sc2.long as long_end_station
from v_rank vr
join top10dic td 
on td.trip_id_a = vr.trip_id_a
join v_trip vt
on td.trip_id = vt.trip_id
join station_csv sc 
on sc.id::text = left(td.trip_id_a,2)
join station_csv sc2 
on sc2.id::text = substring(td.trip_id_a from 4 for 2)

select distinct
td.trip_id_a ,
dense_rank () over (order by trip_qty desc) as ranking
from v_rank vr
join top10dic td 
on td.trip_id_a = vr.trip_id_a
join v_trip vt
on td.trip_id = vt.trip_id
join station_csv sc 
on sc.id::text = left(td.trip_id_a,2)
join station_csv sc2 
on sc2.id::text = substring(td.trip_id_a from 4 for 2)


