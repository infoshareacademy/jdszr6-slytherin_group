-------MAIN CODE--------










------DM CODE ----------

/*Code below creates 2 views and 6 statistics showing weather attributes vs number of daily rides. 
View v3_weather_with_ranges shows weather data + weather attribtues ranges.
v3_daily_rides_with_weather shows cumulative daily rides with weather and weather ranges.
All are filtered to zip code 74107 which is the most popular zip code in terms of total number of rides. 
*/
 
 /* Weather view with 7 calculated columns ordering each observations into one of min-max range of weather attribute like temp,Dew_point,pressure, wind speed, max wind gusts, precipitation & visibility*/ 
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
	where zip_code ='94107'
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
*
from weather_ntiles;


/* View with amount of daily rides & weather on that day & zip code with ranges of weather attributes*/ 
create view v3_daily_rides_with_weather as
with daily_rides as 
	(
	select 
	zip_code trip_zip_code, start_date::date, count(*) daily_rides 
	from trip_csv tc 
	where zip_code = '94107'
	group by zip_code, start_date::date
	order by zip_code, start_date::date
	)
select * 
from daily_rides dr 
join v3_weather_with_ranges vwwr   
on dr.start_date::date||dr.trip_zip_code = vwwr.date::date||cast(vwwr.zip_code as text)
where dr.trip_zip_code='94107'
order by dr.start_date desc;

/*statystyka ilosci przejazdow w robiciu na zip cody i na rozne temperatury*/
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

/*statystyka ilosci przejazdow w robiciu na zip cody i na punkt rosy*/
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

/*statystyka ilosci przejazdow w robiciu na zip cody i na cisnienie*/
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

/*statystyka ilosci przejazdow w robiciu na zip cody i na predkosc wiatru*/
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

/*statystyka ilosci przejazdow w robiciu na zip cody i na porywy wiatru*/
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

/*statystyka ilosci przejazdow w robiciu na zip cody i na widocznosc*/
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

/*Ilosc przejazdow w uzaleznieniu od eventu*/
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
	where zip_code = 94107
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
order by trip_zip_code, ntiles





