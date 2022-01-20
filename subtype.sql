/* Przygotowanie danych  */
create or replace view view_trip as
select
	to_char(start_date, 'yyyy-mm-dd') as date_data,
	start_station_id || '_' || end_station_id as trip_id,
	duration,
	subscription_type,
	zip_code
from
	trip_csv tc
where
	zip_code in (select distinct zip_code::varchar
						from weather_csv)

						
/* Analiza czasu ogólnie, przy podziale na Subscriber i Customer*/
select
	distinct
	subscription_type,
	count(*) over (partition by subscription_type) as trips,
	round(avg(duration) over (partition by subscription_type)/60, 2) as subtype_average_duration,
	case
		when subscription_type = 'Subscriber' then (	select round(percentile_disc(0.1) within group (order by duration)*1.0/60, 2)
																		from view_trip
																		where subscription_type = 'Subscriber')
		when subscription_type = 'Customer' then (select round(percentile_disc(0.1) within group (order by duration)*1.0/60, 2)
																		from view_trip
																		where subscription_type = 'Customer')
	end as tenth_percentile,
	case
		when subscription_type = 'Subscriber' then (	select round(percentile_disc(0.5) within group (order by duration)*1.0/60, 2)
																		from view_trip
																		where subscription_type = 'Subscriber')
		when subscription_type = 'Customer' then (select round(percentile_disc(0.5) within group (order by duration)*1.0/60, 2)
																		from view_trip
																		where subscription_type = 'Customer')
	end as median,
	case
		when subscription_type = 'Subscriber' then (	select round(percentile_disc(0.9) within group (order by duration)*1.0/60, 2)
																		from view_trip
																		where subscription_type = 'Subscriber')
		when subscription_type = 'Customer' then (select round(percentile_disc(0.9) within group (order by duration)*1.0/60, 2)
																		from view_trip
																		where subscription_type = 'Customer')
	end as ninetieth_percentile
from
	view_trip


/* Analiza czasu poszczególnych tras, przy podziale na Subscriber i Customer*/
select 	
	distinct
	vt.trip_id,
	count(*) over (partition by vt.trip_id) as trips,
	round(avg(duration) over (partition by vt.trip_id)*1.0/60, 2) as average_duration,
	subscription_type as subtype,
	count(*) over (partition by vt.trip_id, subscription_type) as subtype_trips,
	round(min(duration) over (partition by vt.trip_id, subscription_type)*1.0/60, 2) as min_duration,
	round(max(duration) over (partition by vt.trip_id, subscription_type)*1.0/60, 2) as max_duration,
	round(avg(duration) over (partition by vt.trip_id, subscription_type)*1.0/60, 2) as subtype_average_duration,
	tenth_percentile,
	median,
	ninetieth_percentile
from
	view_trip vt
join (select
			trip_id,
			round(percentile_disc(0.1) within group (order by duration)*1.0/60, 2) as  tenth_percentile,
			round(percentile_disc(0.5) within group (order by duration)*1.0/60, 2) as median,
			round(percentile_disc(0.9) within group (order by duration)*1.0/60, 2) as ninetieth_percentile
		from
			view_trip vt
		group by
			trip_id) as perc
on vt.trip_id = perc.trip_id
order by
	trip_id, subscription_type
