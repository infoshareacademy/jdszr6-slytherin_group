-------MAIN CODE--------










------DM CODE ----------

/*We need to merge weather & trips tables by date & zip code. Zip code in trips is unreliable so we need to derive it from id of start & end station. 
 * In first step we take station table and add zip code by each city name and create a view v3_station_csv_with_zip_cod - new field is called zip_code_station*/
create materialized view v3_station_csv_with_zip_code as select 
	*,
	case
	when city='Palo Alto' then 94301
	when city='San Jose' then 95113
	when city='Redwood City' then 94063
	when city='Mountain View' then 94041
	when city='San Francisco' then 94107
	else 0
	end as Zip_code_station
from station_csv sc;

/* In second step we add start, end cities & zip codes from station view created in step one to to trips table and create a v3_trips_start_end_city_zip_code with 4 new columns
  start_zip_code & end_zip_code for zip codes and start, end cities for cities*/ 
create materialized view v3_trips_with_cities_zip_codes as 
with trips_plus_end_zip as 
	(
	select 
	sc.city end_city, sc.zip_code_station end_zip_code, 
	tc.id, tc.duration,tc.start_date, tc.start_station_name,tc.start_station_id, tc.end_date, tc.end_station_name, tc.end_station_id, tc.bike_id,tc.subscription_type, tc.zip_code as bad_trip_zip_code,
	tc.start_station_id||'-'||tc.end_station_id trip_route, 1 as ride_no
	from trip_csv tc 
	join v3_station_csv_with_zip_code sc 
	on tc.end_station_id = sc.id 
	)
select scw.city as start_city,scw.zip_code_station as start_zip_code,  trips_plus_end_zip.*
from trips_plus_end_zip
join v3_station_csv_with_zip_code scw 
on trips_plus_end_zip.start_station_id=scw.id;
/*no rows were lost from trips_csv and still 699k trips are there but now with zip codes of start and end station. I.e. there is integrity between start, end station in trips and those in stations table
 * also there is only 1k trips from one city to the other i.e. where start & end cities are different*/

 /* We now create view on top of weather table that clusters all observations by 5ntiles of each Weather and another custom clustering. Those clusters are kept in columns: range_... */ 
create or replace view v3_weather_with_ranges as
/*Order observations into one of 5 ntiles per weather attribute. Those are technical columns that are used to define tiles min-max range.*/
with weather_ntiles as 	
	(
	select 
	*,
	ntile(5) over (order by mean_temperature_f) ntile_mean_temp,
	ntile(5) over (order by mean_dew_point_f) ntile_mean_dew_point,
	ntile(5) over (order by mean_sea_level_pressure_inches) ntile_mean_sea_level_pressure,
	ntile(5) over (order by mean_wind_speed_mph) ntile_mean_wind_speed_mph,
	ntile(5) over (order by max_gust_speed_mph) ntile_max_gust_speed,
	ntile(5) over (order by precipitation_inches) ntile_precipitation_inches,
	ntile(5) over (order by mean_visibility_miles) ntile_mean_visibility_miles
	from weather_csv wc 
	)
/*Order observations into 1 of 5 ranges per each weather attribute ascending*/
select 
ntile_mean_temp||'#'||min(mean_temperature_f) over (partition by ntile_mean_temp)||'-'||max(mean_temperature_f) over (partition by ntile_mean_temp) as range_mean_temp,
ntile_mean_dew_point||'#'||min(mean_dew_point_f) over (partition by ntile_mean_dew_point)||'-'||max(mean_dew_point_f) over (partition by ntile_mean_dew_point) as range_dew_point,
ntile_mean_sea_level_pressure||'#'||round( min(mean_sea_level_pressure_inches) over (partition by ntile_mean_sea_level_pressure)::numeric ,2 )||'-'||round(max(mean_sea_level_pressure_inches) over (partition by ntile_mean_sea_level_pressure)::numeric, 2) as range_sea_level_pressure,
ntile_mean_wind_speed_mph||'#'||min(mean_wind_speed_mph) over (partition by ntile_mean_wind_speed_mph)||'-'||max(mean_wind_speed_mph) over (partition by ntile_mean_wind_speed_mph) as range_wind_speed_mph,
ntile_max_gust_speed||'#'||min(max_gust_speed_mph) over (partition by ntile_max_gust_speed)||'-'||max(max_gust_speed_mph) over (partition by ntile_max_gust_speed) as range_max_gust_speed,
ntile_mean_visibility_miles||'#'|| min(mean_visibility_miles) over (partition by ntile_mean_visibility_miles)||'-'||max(mean_visibility_miles) over (partition by ntile_mean_visibility_miles) as range_mean_visibility_miles,
ntile_precipitation_inches||'#'|| (min(precipitation_inches) over (partition by ntile_precipitation_inches))::double precision||'-'||(max(precipitation_inches) over (partition by ntile_precipitation_inches))::double precision as range_precipitation_inches,
107.3724420191 as tot_avg, 110 as tot_median, /*Need this for % calculation of averages & medians in ranges*/
case 
	when weather_ntiles.mean_sea_level_pressure_inches between 29.6 and 30.2 then 'Ok' 
	when weather_ntiles.mean_sea_level_pressure_inches>30.2 then 'High'
	when weather_ntiles.mean_sea_level_pressure_inches <29.6 then 'Low'
	else 'Error'
end as Cluster_pressure /*Definitions of low, normal, high taken from https://dnr.wisconsin.gov/topic/labCert/BODCalibration2.html*/,
case 
	when weather_ntiles.mean_temperature_f between 60.8 and 77 then 'Ok' 
	when weather_ntiles.mean_temperature_f>77 then 'High'
	when weather_ntiles.mean_temperature_f<60.8 then 'Low'
	else 'Error'
end as Cluster_temperature, /*Definitions of low, normal, high https://www.arabiaweather.com/en/content/what-are-the-best-weather-conditions-to-enjoy-cycling*/
case 
	when weather_ntiles.mean_wind_speed_mph between 0 and 12 then 'Gentle' 
	when weather_ntiles.mean_wind_speed_mph between 12 and 24 then 'Moderate'
	when weather_ntiles.mean_wind_speed_mph>24 then 'Extreme'
	else 'Error'
end as Cluster_wind, /*Definitions from https://www.weather.gov/pqr/wind*/
case 
	when weather_ntiles.mean_dew_point_f between 0 and 55 then 'Ok' 
	when weather_ntiles.mean_dew_point_f between 55 and 65 then 'Strong'
	when weather_ntiles.mean_dew_point_f>65 then 'Opressive'
	else 'Error'
end as Cluster_dew_point,
case
	when length(weather_ntiles.events)<>0 then 'Rain_Fog_Etc' /*jak jest deszcz albo mgla to zla pogoda*/
	when length(weather_ntiles.events)=0 then 'No Rain_Fog_etc' 
end as Cluster_events,
*
from weather_ntiles;

/*In next step we create detailed view combining weather data & all rides*/ 
create materialized view v3_rides_with_weather as
select 
* 
from v3_trips_with_cities_zip_codes tc
join v3_weather_with_ranges vwwr
on tc.start_zip_code||'-'||tc.start_date::date=vwwr.zip_code||'-'||vwwr.date;

/*In next step we create aggregated view combining weather data & daily rides numbers*/ 
create view v3_daily_rides_with_weather as
with daily_rides as 
	(
	select 
	start_zip_code trip_zip_code, start_date::date, count(*) daily_rides
	from v3_trips_with_cities_zip_codes tc 
	group by start_zip_code, start_date::date
	order by start_zip_code, start_date::date
	)
select * 
from daily_rides dr 
join v3_weather_with_ranges vwwr   
on dr.start_date::date||'.'||dr.trip_zip_code = vwwr.date::date||'.'||cast(vwwr.zip_code as text)
order by dr.start_date desc;

/*In next step we create an hourly status view on status table - to reduce the size needed to assess occupation of station by hour*/
create materialized view v3_status_hourly as
select 
station_id, 
date_trunc('hour',time) date_s, 
avg(bikes_available) as bikes_available,
avg(docks_available) as docks_available
from status_csv sc group by station_id, date_trunc('hour',time) 

with dupa as
	(select sum(vrww.ride_no) hourly_rides from v3_rides_with_weather vrww group by date_part('hour',start_date)) 
select avg(hourly_rides) from dupa

/*Statistics on hourly rides number vs team temp ntiles*/
with avg_rides_per_temp as
	(
	select 
		trip_zip_code, range_mean_temp ntiles, 
		min(daily_rides) r_min,
		percentile_cont(0.10) within group (order by daily_rides asc) r_perc_10,
		avg(daily_rides) r_avg,
		percentile_cont(0.5) within group (order by daily_rides asc) r_median,
		stddev(daily_rides) as r_std_dev,
		percentile_cont(0.90) within group (order by daily_rides asc) perc_90,
		max(daily_rides) r_max
		from v3_daily_rides_with_weather
		group by trip_zip_code, range_mean_temp
		order by trip_zip_code, range_mean_temp 
	)
select
case 
when 1=1 then 'Mean Temperature F' end Rides_vs,
trip_zip_code zip_code, ntiles, r_min, 
round(r_perc_10) perc10, round(r_avg) r_avg, 
round((r_avg-lag(r_avg) over (partition by trip_zip_code order by ntiles))/(lag(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_prev_ntile, 
round((r_avg-first_value(r_avg) over (partition by trip_zip_code order by ntiles))/(first_value(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_1st_ntile, 
round(r_median) r_median,
round((r_median-lag(r_median) over (partition by trip_zip_code order by ntiles))/(lag(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_prev_ntile, 
round((r_median-first_value(r_median) over (partition by trip_zip_code order by ntiles))/(first_value(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_1st_ntile, 
round(perc_90) perc90, r_max 
from avg_rides_per_temp order by trip_zip_code, ntiles;

/*Statistics on hourly rides number vs dew point ntiles*/
with avg_rides_per_weather as
	(
	select 
		trip_zip_code, range_dew_point ntiles, 
		min(daily_rides) r_min,
		percentile_cont(0.10) within group (order by daily_rides asc) r_perc_10,
		avg(daily_rides) r_avg,
		percentile_cont(0.5) within group (order by daily_rides asc) r_median,
		stddev(daily_rides) as r_std_dev,
		percentile_cont(0.90) within group (order by daily_rides asc) perc_90,
		max(daily_rides) r_max
		from v3_daily_rides_with_weather
		group by trip_zip_code, range_dew_point
		order by trip_zip_code, range_dew_point 
	)
select
case 
when 1=1 then 'Mean Dew Point F' end Rides_vs,
trip_zip_code zip_code, ntiles, r_min, 
round(r_perc_10) perc10, round(r_avg) r_avg, 
round((r_avg-lag(r_avg) over (partition by trip_zip_code order by ntiles))/(lag(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_prev_ntile, 
round((r_avg-first_value(r_avg) over (partition by trip_zip_code order by ntiles))/(first_value(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_1st_ntile, 
round(r_median) r_median,
round((r_median-lag(r_median) over (partition by trip_zip_code order by ntiles))/(lag(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_prev_ntile, 
round((r_median-first_value(r_median) over (partition by trip_zip_code order by ntiles))/(first_value(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_1st_ntile, 
round(perc_90) perc90, r_max 
from avg_rides_per_weather order by trip_zip_code, ntiles;

/*Statistics on hourly rides number vs air pressure ntiles*/
with avg_rides_per_weather as
	(
	select 
		trip_zip_code, range_sea_level_pressure ntiles, 
		min(daily_rides) r_min,
		percentile_cont(0.10) within group (order by daily_rides asc) r_perc_10,
		avg(daily_rides) r_avg,
		percentile_cont(0.5) within group (order by daily_rides asc) r_median,
		stddev(daily_rides) as r_std_dev,
		percentile_cont(0.90) within group (order by daily_rides asc) perc_90,
		max(daily_rides) r_max
		from v3_daily_rides_with_weather
		group by trip_zip_code, range_sea_level_pressure
		order by trip_zip_code, range_sea_level_pressure
	)
select
case 
when 1=1 then 'Air Pressure Inches' end Rides_vs,
trip_zip_code zip_code, ntiles, r_min, 
round(r_perc_10) perc10, round(r_avg) r_avg, 
round((r_avg-lag(r_avg) over (partition by trip_zip_code order by ntiles))/(lag(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_prev_ntile, 
round((r_avg-first_value(r_avg) over (partition by trip_zip_code order by ntiles))/(first_value(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_1st_ntile, 
round(r_median) r_median,
round((r_median-lag(r_median) over (partition by trip_zip_code order by ntiles))/(lag(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_prev_ntile, 
round((r_median-first_value(r_median) over (partition by trip_zip_code order by ntiles))/(first_value(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_1st_ntile, 
round(perc_90) perc90, r_max 
from avg_rides_per_weather order by trip_zip_code, ntiles;

/*Statistics on hourly rides number vs wind speed ntiles*/
with avg_rides_per_weather as
	(
	select 
		trip_zip_code, range_wind_speed_mph ntiles, 
		min(daily_rides) r_min,
		percentile_cont(0.10) within group (order by daily_rides asc) r_perc_10,
		avg(daily_rides) r_avg,
		percentile_cont(0.5) within group (order by daily_rides asc) r_median,
		stddev(daily_rides) as r_std_dev,
		percentile_cont(0.90) within group (order by daily_rides asc) perc_90,
		max(daily_rides) r_max
		from v3_daily_rides_with_weather
		group by trip_zip_code, range_wind_speed_mph
		order by trip_zip_code, range_wind_speed_mph
	)
select
case 
when 1=1 then 'Wind Speed mph' end Rides_vs,
trip_zip_code zip_code, ntiles, r_min, 
round(r_perc_10) perc10, round(r_avg) r_avg, 
round((r_avg-lag(r_avg) over (partition by trip_zip_code order by ntiles))/(lag(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_prev_ntile, 
round((r_avg-first_value(r_avg) over (partition by trip_zip_code order by ntiles))/(first_value(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_1st_ntile, 
round(r_median) r_median,
round((r_median-lag(r_median) over (partition by trip_zip_code order by ntiles))/(lag(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_prev_ntile, 
round((r_median-first_value(r_median) over (partition by trip_zip_code order by ntiles))/(first_value(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_1st_ntile, 
round(perc_90) perc90, r_max 
from avg_rides_per_weather order by trip_zip_code, ntiles;

/*Statistics on hourly rides number vs wind gusts ntiles*/
with avg_rides_per_weather as
	(
	select 
		trip_zip_code, range_max_gust_speed ntiles, 
		min(daily_rides) r_min,
		percentile_cont(0.10) within group (order by daily_rides asc) r_perc_10,
		avg(daily_rides) r_avg,
		percentile_cont(0.5) within group (order by daily_rides asc) r_median,
		stddev(daily_rides) as r_std_dev,
		percentile_cont(0.90) within group (order by daily_rides asc) perc_90,
		max(daily_rides) r_max
		from v3_daily_rides_with_weather
		group by trip_zip_code, range_max_gust_speed
		order by trip_zip_code, range_max_gust_speed
	)
select
case 
when 1=1 then 'Wind Gusts mph' end Rides_vs,
trip_zip_code zip_code, ntiles, r_min, 
round(r_perc_10) perc10, round(r_avg) r_avg, 
round((r_avg-lag(r_avg) over (partition by trip_zip_code order by ntiles))/(lag(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_prev_ntile, 
round((r_avg-first_value(r_avg) over (partition by trip_zip_code order by ntiles))/(first_value(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_1st_ntile, 
round(r_median) r_median,
round((r_median-lag(r_median) over (partition by trip_zip_code order by ntiles))/(lag(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_prev_ntile, 
round((r_median-first_value(r_median) over (partition by trip_zip_code order by ntiles))/(first_value(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_1st_ntile, 
round(perc_90) perc90, r_max 
from avg_rides_per_weather order by trip_zip_code, ntiles;

/*Statistics on hourly rides number vs visibility ntiles*/
with avg_rides_per_weather as
	(
	select 
		trip_zip_code, range_mean_visibility_miles ntiles, 
		min(daily_rides) r_min,
		percentile_cont(0.10) within group (order by daily_rides asc) r_perc_10,
		avg(daily_rides) r_avg,
		percentile_cont(0.5) within group (order by daily_rides asc) r_median,
		stddev(daily_rides) as r_std_dev,
		percentile_cont(0.90) within group (order by daily_rides asc) perc_90,
		max(daily_rides) r_max
		from v3_daily_rides_with_weather
		group by trip_zip_code, range_mean_visibility_miles
		order by trip_zip_code, range_mean_visibility_miles
	)
select
case 
when 1=1 then 'Visibility miles' end Rides_vs,
trip_zip_code zip_code, ntiles, r_min, 
round(r_perc_10) perc10, round(r_avg) r_avg, 
round((r_avg-lag(r_avg) over (partition by trip_zip_code order by ntiles))/(lag(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_prev_ntile, 
round((r_avg-first_value(r_avg) over (partition by trip_zip_code order by ntiles))/(first_value(r_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_1st_ntile, 
round(r_median) r_median,
round((r_median-lag(r_median) over (partition by trip_zip_code order by ntiles))/(lag(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_prev_ntile, 
round((r_median-first_value(r_median) over (partition by trip_zip_code order by ntiles))/(first_value(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_1st_ntile, 
round(perc_90) perc90, r_max 
from avg_rides_per_weather order by trip_zip_code, ntiles;

/*Statistics on hourly rides number vs various weather events ntiles*/
with avg_rides_per_weathers as
	(
	select 
	trip_zip_code, lower(events) ntiles, 
	count(1) as days_with,
	min(daily_rides) rides_min, 
	round(percentile_cont(0.10) within group (order by daily_rides asc)) perc_10,
	round(avg(daily_rides)) rides_avg, 
	round(percentile_cont(0.5) within group (order by daily_rides asc)) r_median,
	round(percentile_cont(0.90) within group (order by daily_rides asc)) perc_90,
	max(daily_rides) max_rides
	from v3_daily_rides_with_weather vdraw 
	group by trip_zip_code, lower(events) 
	)
select 
case 
when 1=1 then 'Weather Event' end Rides_vs,
trip_zip_code zip_code, ntiles, rides_min r_min, perc_10, rides_avg r_avg,
round((rides_avg-lag(rides_avg) over (partition by trip_zip_code order by ntiles))/(lag(rides_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_prev_ntile,
round((rides_avg-first_value(rides_avg) over (partition by trip_zip_code order by ntiles))/(first_value(rides_avg) over (partition by trip_zip_code order by ntiles))*100)||'%' r_avg_vs_first_ntile,
r_median,
round((r_median-lag(r_median) over (partition by trip_zip_code order by ntiles))/(lag(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_median_vs_prev_ntile,
round((r_median-first_value(r_median) over (partition by trip_zip_code order by ntiles))/(first_value(r_median) over (partition by trip_zip_code order by ntiles))*100)||'%' r_medina_vs_first_ntile,
perc_90,max_rides r_max
from avg_rides_per_weathers 
order by trip_zip_code, ntiles;



