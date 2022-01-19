
/*weekendy*/
create view v_weekendy as
SELECT distinct time, extract(year from time)||'-'||extract(month from time)||'-'||extract(day from time) as nowa_data
  FROM status_csv sc 
 WHERE EXTRACT(ISODOW FROM sc.time) IN (6, 7)
 
 /*dni pracujace*/
create view v_dni_robocze as
SELECT distinct time, extract(year from time)||'-'||extract(month from time)||'-'||extract(day from time) as nowa_data
  FROM status_csv sc 
 WHERE EXTRACT(ISODOW FROM sc.time) IN (1, 2,3,4,5)
 
 /*ekstrakcja godziny *//
 select extract(hour from time) as godzina
 from status_csv sc 

 /*podzial na pory dnia*/
create view v_pora_dnia1 as
SELECT time, CASE 
        WHEN h >= 0  AND h <= 7  THEN 'dawn'  -- including 0 !
        WHEN h >  7  AND h <= 12 THEN 'morning'
        WHEN h > 12  AND h <= 20 THEN 'evening'
        WHEN h > 20              THEN 'night'
       END AS moment
FROM  (
    SELECT time, extract(hour from time) AS h
    FROM   status_csv sc 
    ) x

/*srednia, min i max rowerow po stacji i dniu*/
select 
sc2.station_id, 
avg(sc2.bikes_available),
min(sc2.bikes_available),max(sc2.bikes_available),
extract(year from time)||'-'||extract(month from time)||'-'||extract(day from time) as nowa_data
from status_csv sc2 
group by sc2.station_id, extract(year from time)||'-'||extract(month from time)||'-'||extract(day from time)

/*srednia, min i max rowerow po stacji i w weekendy*/
select *,
avg(sc.bikes_available) over (partition by nowa_data) as sr_w_weekend,
min(sc.bikes_available) over (partition by nowa_data) as min_w_weekend,
max(sc.bikes_available) over (partition by nowa_data) as max_w_weekend
from status_csv sc 
join v_weekendy 
on v_weekendy.time=sc.time



/*srednia, min i max rowerow po stacji i w dni pracujace*/

select *,
avg(sc.bikes_available) over (partition by  nowa_data) as sr_w_drobocze,
min(sc.bikes_available) over (partition by  nowa_data) as min_w_drobocze,
max(sc.bikes_available) over (partition by nowa_data) as max_w_drobocze
from status_csv sc 
join v_dni_robocze
on v_dni_robocze.time=sc.time



/*polaczenie z tripami Mateusza */
--na miesiace
select distinct v_top10a.trip_id,
extract(year from sc2.time)||'-'||extract(month from sc2.time) as rok_miesiac,
avg(sc2.bikes_available) over (partition by  extract(year from sc2.time)||'-'||extract(month from sc2.time)) as sr_miesieczna,
min(sc2.bikes_available) over (partition by  extract(year from sc2.time)||'-'||extract(month from sc2.time)) as min_miesieczne,
max(sc2.bikes_available) over (partition by  extract(year from sc2.time)||'-'||extract(month from sc2.time)) as max_miesieczne
from status_csv sc2 
join v_top10a 
on sc2.station_id =v_top10a.start_station_id

-- srednia pokazuje, ze jeszcze jest potencjal na te trasy we wszystkich miesiacach, okolo 50% rowerow jest jeszcze dostepnych 

--na weekendy
select v_top10a.trip_id,nowa_data,
avg(sc.bikes_available) over (partition by nowa_data) as sr_w_weekend,
min(sc.bikes_available) over (partition by nowa_data) as min_w_weekend,
max(sc.bikes_available) over (partition by nowa_data) as max_w_weekend
from status_csv sc 
join v_weekendy 
on v_weekendy.time=sc.time
join v_top10a 
on sc.station_id =v_top10a.start_station_id


--na dni robocze
select *,
avg(sc.bikes_available) over (partition by  nowa_data) as sr_w_drobocze,
min(sc.bikes_available) over (partition by  nowa_data) as min_w_drobocze,
max(sc.bikes_available) over (partition by nowa_data) as max_w_d.robocze
from status_csv sc 
join v_dni_robocze
on v_dni_robocze.time=sc.time
join v_top10a 
on sc.station_id =v_top10a.start_station_id

--na pory dnia
select distinct v_top10a.trip_id, moment,
avg(sc2.bikes_available) over (partition by  moment ) as sr_na_pore_dnia,
min(sc2.bikes_available) over (partition by  moment) as min_na_pore_dnia,
max(sc2.bikes_available) over (partition by  moment) as max_na_pore_dnia
from status_csv sc2 
join v_top10a 
on sc.station_id =v_top10a.start_station_id
join v_pora_dnia1
on v_pora_dnia1.station_id=sc.station_id

--


/*z ktorych stacji do ktorych i kiedy warto przerzucic rowery*/


create view v_przen_rower as
select distinct *,
case
	 when srednia >=10 then 'przeniesc rower'
	 when srednia between 7 and 9 then 'zostawic'
	 when srednia <=6 then 'tu przeniesc'
	 else 'zostawic' end czy_przeniesc_rower
from
	(select sc.station_id, avg(sc.bikes_available) over 
	(partition by extract(year from sc.time)||'-'||extract(month from sc.time)) as srednia
	from status_csv sc 
	group by sc.station_id, extract(year from sc.time)||'-'||extract(month from sc.time), sc.bikes_available )y 

select *
from v_przen_rower
join v_ranking2 
on v_ranking2.start_station_id=v_przen_rower.station_id

/*sugerowane trasy, ktore sa malo oblegane a maja dostepnosc rowerow - na nie warto dac rabat w subskrybcji - do obrobki w tableau*/
select *
from v_ranking2 
join status_csv sc 
on sc.station_id=v_ranking2.start_station_id
where ranking >=10
order by ranking


