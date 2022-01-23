-- J.Witek
-- Percentyle, odchylenie standardowe, NULLE

-- precipitation_inches T - ma³a iloœæ której nie da siê zmierzyæ, mo¿na zamieniæ na 0

update weather_csv 
set precipitation_inches = '0'
where precipitation_inches = 'T'

select * from weather_csv wc 


-- problem ze zmian¹ typu danych ma float4 w weather_csv precipitation_inches


-- Sprawdzenie nulli w danych liczbowych

select sc.bikes_available
from status_csv sc 
where sc.bikes_available is null

select sc.docks_available 
from status_csv sc 
where sc.docks_available  is null

select sc2.lat 
from station_csv sc2 
where sc2.lat is null

select sc2.long 
from station_csv sc2 
where sc2.long is null

select sc2.dock_count 
from station_csv sc2 
where sc2.dock_count is null

select tc.duration 
from trip_csv tc 
where tc.duration is null

select tc.start_station_id 
from trip_csv tc 
where tc.start_station_id  is null

select tc.end_station_id 
from trip_csv tc 
where tc.end_station_id  is null



select * 
from weather_csv wc 
where wc.max_temperature_f is null 
or wc.mean_temperature_f is null 
or wc.min_temperature_f is null
or wc.max_dew_point_f is null
or wc.mean_dew_point_f is null
or wc.min_dew_point_f is null
or wc.max_humidity is null
or wc.mean_humidity is null
or wc.min_humidity is null
or wc.max_sea_level_pressure_inches is null
or wc.mean_sea_level_pressure_inches is null
or wc.min_sea_level_pressure_inches is null
or wc.max_visibility_miles is null
or wc.mean_visibility_miles is null
or wc.min_visibility_miles is null
or wc.max_wind_speed_mph is null
or wc.mean_wind_speed_mph is null
or wc.max_gust_speed_mph is null
or wc.precipitation_inches is null
or wc.cloud_cover is null
or wc.wind_dir_degrees is null

-- co zrobic z wartosciami null ¿eby nie zak³amywaæ wyników? zostawiæ, usun¹æ? One nie wp³ywaj¹ na wyniki (??)


-- Odchylenie standardowe danych w tabeli weather

select stddev(wc.max_temperature_f), stddev(wc.mean_temperature_f), stddev(wc.min_temperature_f)
from weather_csv wc 

select stddev(wc.max_dew_point_f), stddev(wc.mean_dew_point_f), stddev(wc.min_dew_point_f)
from weather_csv wc 

select stddev(wc.max_humidity), stddev(wc.mean_humidity), stddev(wc.min_humidity)
from weather_csv wc 

select stddev(wc.max_temperature_f), stddev(wc.mean_temperature_f), stddev(wc.min_temperature_f)
from weather_csv wc 

select stddev(wc.max_sea_level_pressure_inches), stddev(wc.mean_sea_level_pressure_inches), stddev(wc.min_sea_level_pressure_inches)
from weather_csv wc 

select stddev(wc.max_visibility_miles), stddev(wc.mean_visibility_miles), stddev(wc.min_visibility_miles)
from weather_csv wc 

select stddev(wc.max_wind_speed_mph), stddev(wc.mean_wind_speed_mph), stddev(wc.max_gust_speed_mph)
from weather_csv wc 

select stddev(wc.max_temperature_f), stddev(wc.mean_temperature_f), stddev(wc.min_temperature_f)
from weather_csv wc 



--??
select stddev(wc.precipitation_inches::numeric)
from weather_csv wc

select stddev(wc.cloud_cover)
from weather_csv wc 


--percentyle

select
percentile_disc(0.1) within group (order by wc.max_temperature_f),
percentile_disc(0.5) within group (order by wc.max_temperature_f),
percentile_disc(0.9) within group (order by wc.max_temperature_f)
from weather_csv wc 


select
percentile_disc(0.1) within group (order by wc.mean_temperature_f),
percentile_disc(0.5) within group (order by wc.mean_temperature_f),
percentile_disc(0.9) within group (order by wc.mean_temperature_f)
from weather_csv wc 


select
percentile_disc(0.1) within group (order by wc.min_temperature_f),
percentile_disc(0.5) within group (order by wc.min_temperature_f),
percentile_disc(0.9) within group (order by wc.min_temperature_f)
from weather_csv wc 

select
percentile_disc(0.1) within group (order by wc.max_dew_point_f),
percentile_disc(0.5) within group (order by wc.max_dew_point_f),
percentile_disc(0.9) within group (order by wc.max_dew_point_f)
from weather_csv wc 

select
percentile_disc(0.1) within group (order by wc.mean_dew_point_f),
percentile_disc(0.5) within group (order by wc.mean_dew_point_f),
percentile_disc(0.9) within group (order by wc.mean_dew_point_f)
from weather_csv wc 

select
percentile_disc(0.1) within group (order by wc.min_dew_point_f),
percentile_disc(0.5) within group (order by wc.min_dew_point_f),
percentile_disc(0.9) within group (order by wc.min_dew_point_f)
from weather_csv wc 

select
percentile_disc(0.1) within group (order by wc.max_visibility_miles),
percentile_disc(0.5) within group (order by wc.max_visibility_miles),
percentile_disc(0.9) within group (order by wc.max_visibility_miles)
from weather_csv wc 

select
percentile_disc(0.1) within group (order by wc.mean_visibility_miles),
percentile_disc(0.5) within group (order by wc.mean_visibility_miles),
percentile_disc(0.9) within group (order by wc.mean_visibility_miles)
from weather_csv wc 

select
percentile_disc(0.1) within group (order by wc.min_visibility_miles),
percentile_disc(0.5) within group (order by wc.min_visibility_miles),
percentile_disc(0.9) within group (order by wc.min_visibility_miles)
from weather_csv wc 

select
percentile_disc(0.1) within group (order by wc.max_wind_speed_mph),
percentile_disc(0.5) within group (order by wc.max_wind_speed_mph),
percentile_disc(0.9) within group (order by wc.max_wind_speed_mph)
from weather_csv wc 

select
percentile_disc(0.1) within group (order by wc.mean_wind_speed_mph),
percentile_disc(0.5) within group (order by wc.mean_wind_speed_mph),
percentile_disc(0.9) within group (order by wc.mean_wind_speed_mph)
from weather_csv wc

select
percentile_disc(0.1) within group (order by wc.max_gust_speed_mph),
percentile_disc(0.5) within group (order by wc.max_gust_speed_mph),
percentile_disc(0.9) within group (order by wc.max_gust_speed_mph)
from weather_csv wc



-- odchlenie standardowe danych w tabeli trips, percentyle // duration


select stddev(tc.duration)
from trip_csv tc 

select
percentile_disc(0.1) within group (order by tc.duration),
percentile_disc(0.5) within group (order by tc.duration),
percentile_disc(0.9) within group (order by tc.duration)
from trip_csv tc 









































