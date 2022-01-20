
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

--problem z niewyœwietlaniem wyników po dniach tygodnia, ale pokazuje po porach dnia
--start station + _ + end station