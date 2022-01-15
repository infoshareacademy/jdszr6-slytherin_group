
/*bike availability*/

select distinct s.id, t.id,
count(bike_id) over (partition by s.id)
from station s 
join trip t on s.id=t.start_station_id


