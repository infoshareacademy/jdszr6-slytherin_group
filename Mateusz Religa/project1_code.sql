-- subskrybcje w czasie

select distinct 
tc.subscription_type ,
to_char (tc.start_date, 'yyyy-mm-dd') as year_month,
count(*) over (partition by tc.subscription_type, to_char (tc.start_date, 'yyyy-mm-dd')) as subscription_type_trips_count
from trip_csv tc 
order by to_char (tc.start_date, 'yyyy-mm-dd')

--po³¹czenie tras_ID
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



--widok z percentylami po przejazdach
create or replace view v_percentile as
select 
trip_name,
percentile_disc(0.1) within group (order by duration) as per_01,
percentile_disc(0.5) within group (order by duration) as per_05,
percentile_disc(0.9) within group (order by duration) as per_09
from v_trip
group by trip_name


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

-- generowanie top 10
select *
from v_ranking 
where ranking <=10

--wgrany z csv s³ownik na top10
select *
from top10dic tdc 

--dogranie s³ownika top 10 do trips by wyliczyæ statystyki
--mo¿na z niej wyci¹gaæ wszystkie dane z tabeli trips po top 10
select *,
vt.start_station_name ,
vt.end_station_name ,
sc.lat as lat_start_station,
sc.long as long_start_station,
sc2.lat as lat_end_station,
sc2.long as long_end_station,
avg(vt.duration) over (partition by td.trip_id_a) as trip_avg,
count(*) over (partition by td.trip_id_a) as trip_qty,
dense_rank () over (partition by td.trip_id_a) as ranking
from v_trip vt 
join top10dic td 
on td.trip_id = vt.trip_id 
join station_csv sc 
on sc.id = vt.start_station_id 
join station_csv sc2 
on sc2.id = vt.end_station_id 






select distinct
tc.start_station_name ,
tc.end_station_name ,
tc.start_station_id ,
sc.lat as lat_start_station,
sc.long as long_start_station,
tc.end_station_id ,
sc2.lat as lat_end_station,
sc2.long as long_end_station,
vt.ranking,
vt.trips_qty,
vt.trip_name
from trip_csv tc 
left join station_csv sc 
on sc.id = tc.start_station_id 
left join station_csv sc2 
on sc2.id = tc.end_station_id 
join v_top_10_list vt 
on vt.trip_name = tc.start_station_name ||' - '||tc.end_station_name 

drop view v_dic_trip

