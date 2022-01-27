
create view v_trips as
select *, 
to_timestamp(tc.start_date, 'mm-dd-yyyy hh24:mi') as start_time,
to_timestamp(tc.end_date, 'mm-dd-yyyy hh24:mi') as end_time
from trip_csv tc 

create view v_trips_weekdays3 as
select *, 
to_char(start_time, 'day') as day_of_week_start,
to_char(end_time, 'day') as day_of_week_end,
end_time - start_time as time_of_ride,
case 
	when extract(hour from start_time) > 4 and extract(hour from start_time) < 11 then 'morning'
	when extract(hour from start_time) >= 11 and extract(hour from start_time) < 15 then 'midday'
	when extract(hour from start_time) >= 15 and extract(hour from start_time) < 19 then 'afternoon'
	when extract(hour from start_time) >= 19 and extract(hour from start_time) < 21 then 'evening'
	else 'night'
end as time_of_day
from v_trips

select day_of_week_start, count(*)
from v_trips_weekdays3
group by day_of_week_start

select *
from v_trips_weekdays3
where day_of_week_start like 'monday%'

select *
from v_trips_weekdays2
where time_of_day = 'night'


select distinct to_char(start_time, 'yyyy-mm') as rok_miesiac, 
day_of_week_start,
avg(time_of_ride) over (partition by to_char(start_time, 'yyyy-mm'), day_of_week_start) as srednia_czasu_przejazdow,
avg(duration) over (partition by to_char(start_time, 'yyyy-mm'), day_of_week_start) as srednia_przejazdow
from v_trips_weekdays2
group by start_time, day_of_week_start, time_of_ride, duration
order by to_char(start_time, 'yyyy-mm')


select distinct to_char(start_time, 'yyyy-mm-dd') as dzien,
day_of_week_start,
extract(hour from start_time) as godzina,
count(id) over (partition by to_char(start_time, 'yyyy-mm-dd'), extract(hour from start_time)) as ilosc_przejazdow
from v_trips_weekdays2
group by id, start_time, day_of_week_start
order by to_char(start_time, 'yyyy-mm-dd')


select *, start_station_name || '_' || end_station_name as stacje
from v_trips_weekdays2


select distinct 
to_char(start_time, 'yyyy-mm-dd') as dzien,
day_of_week_start,
extract(hour from start_time) as godzina,
subscription_type,
count(id) over (partition by to_char(start_time, 'yyyy-mm-dd'), extract(hour from start_time), subscription_type) as ilosc_przejazdow
from v_trips_weekdays2
group by id, start_time, day_of_week_start, subscription_type
order by to_char(start_time, 'yyyy-mm-dd')


select distinct subscription_type,
to_char(start_time, 'yyyy-mm-dd') as dzien,
day_of_week_start,
count(id) over (partition by to_char(start_time, 'yyyy-mm-dd'), subscription_type) as ilosc_przejazdow
from v_trips_weekdays2
group by id, start_time, day_of_week_start, subscription_type
order by to_char(start_time, 'yyyy-mm-dd')

