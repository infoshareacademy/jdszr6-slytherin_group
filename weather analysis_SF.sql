/*ekstrakcja roku z daty*/

select substring(date,-4,4) as rok
from weather

/*ekstrakcja miesiaca z daty*/

select substring(date,1,2) as miesiac
from weather

/*polaczenie roku i miesiaca*/
select substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac
from weather


/*temperatura*/
/*srednia maxymalna temperatura na miesiac */

create view v_max_srtemp1 as
select max_temperature_f, substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(max_temperature_f) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_max_temp_na_miesiac
from weather
where zip_code like '94%';


/*odchylenie standardowe*/
select max_temperature_f, SQUARE(sum(power((max_temperature_f-sr_max_temp_na_miesiac),2))/count(*)) as odchylenie
from v_max_srtemp1


/*srednia minimalna temperatura na miesiac (pomijajac lata)*/
create view v_min_srtemp1 as
select min_temperature_f, substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(min_temperature_f) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_min_temp_na_miesiac
from weather
where zip_code like '94%';

/*odchylenie standardowe*/
select min_temperature_f, SQUARE(sum(power((min_temperature_f-sr_min_temp_na_miesiac),2))/count(*)) as odchylenie
from v_min_srtemp1

/*srednia temperatura na miesiac liczac wg sredniej*/

create view v_mean_srtemp1 as
select mean_temperature_f , substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(mean_temperature_f) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_mean_temp_na_miesiac
from weather
where zip_code like '94%';

/*odchylenie standardowe*/
select mean_temperature_f, SQUARE(sum(power((mean_temperature_f-sr_mean_temp_na_miesiac),2))/count(*)) as odchylenie
from v_mean_srtemp1

/*podzial na  zbiory*/

select zip_code, substring(date,1,2) || '-' || substring(date,-4,4), avg(mean_temperature_f) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)), 
	ntile(4) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4))
from weather
where zip_code like '94%';

/*podzialy z widoku i ranking*/
select *
from v_mean_srtemp1
order by sr_mean_temp_na_miesiac DESC

create view v_temp_ranking3 as
select rok_i_miesiac, mean_temperature_f,round(sr_mean_temp_na_miesiac,2),
DENSE_RANK () over (order by sr_mean_temp_na_miesiac DESC) as ranking
from v_mean_srtemp1;

/*kwartyle*/

select *
from v_temp_ranking3
where ranking between 1 AND 5

select *
from v_temp_ranking3
where ranking between 6 AND 10

select *
from v_temp_ranking3
where ranking between 11 AND 15

select *
from v_temp_ranking3
where ranking between 16 AND 20

/*visibility*/
create view v_meanvisib as
select mean_visibility_miles , substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(mean_visibility_miles) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_mean_visibility_na_miesiac
from weather
where zip_code like '94%';

 /*podzialy z widoku i ranking*/
select *
from v_meanvisib
order by sr_mean_visibility_na_miesiac DESC

create view v_meanvisib2 as
select rok_i_miesiac, mean_visibility_miles,round(sr_mean_visibility_na_miesiac,2),
DENSE_RANK () over (order by sr_mean_visibility_na_miesiac DESC) as ranking
from v_meanvisib;

/*kwartyle*/

select *
from v_meanvisib2
where ranking between 1 AND 5

select *
from v_meanvisib2
where ranking between 6 AND 10

select *
from v_meanvisib2
where ranking between 11 AND 15

select *
from v_meanvisib2
where ranking between 16 AND 20


select max_visibility_miles _temperature_f , substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(max_visibility_miles) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_max_visibility_na_miesiac
from weather
where zip_code like '94%';

select min_visibility_miles , substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(min_visibility_miles) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_min_visibility_na_miesiac
from weather
where zip_code like '94%';

/*opady*/


/*czestotliwosc opadow*/

select count(1), substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac
from weather w 
WHERE precipitation_inches>0 and zip_code like '94%'
group by substring(date,1,2) || '-' || substring(date,-4,4) 


select count(1), substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac
from weather w 
WHERE events = 'Rain' and zip_code like '94%'
group by substring(date,1,2) || '-' || substring(date,-4,4) 

/*czestotliwosc mlgy*/

select count(1), substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac
from weather w 
WHERE events = 'Fog' and zip_code like '94%'
group by substring(date,1,2) || '-' || substring(date,-4,4) 

/*czestotliwosc mgly i deszczu*/

select count(1), substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac
from weather w 
WHERE events = 'Fog-Rain' and zip_code like '94%';
group by substring(date,1,2) || '-' || substring(date,-4,4) 

/*kod kontrolny*/

select precipitation_inches, substring(date,1,2) || '-' || substring(date,-4,4) 
from weather w 
where substring(date,1,2) || '-' || substring(date,-4,4) = '1/-2014' and precipitation_inches >0 and zip_code like '94%'
order by date; 





/*max opadow*/

select precipitation_inches, substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
max(precipitation_inches) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as max_opadow
from weather
where zip_code like '94%';

/*srednia opadow*/
create view v_sropadow as
select precipitation_inches, substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(precipitation_inches) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_opadow_na_miesiac
from weather
where zip_code like '94%';


/*podzialy z widoku i ranking*/
select *
from  v_sropadow 
order by sr_opadow_na_miesiac DESC

create view v_sropadow_ranking as
select rok_i_miesiac, precipitation_inches,round(sr_opadow_na_miesiac,2),
DENSE_RANK () over (order by sr_opadow_na_miesiac DESC) as ranking
from v_sropadow;

/*kwartyle*/

select *
from v_sropadow_ranking
where ranking between 1 AND 5

select *
from v_sropadow_ranking
where ranking between 6 AND 10

select *
from v_sropadow_ranking
where ranking between 11 AND 15

select *
from v_sropadow_ranking
where ranking between 16 AND 20



/*wiatr*/


/*sredni wiatr*/ 
create view v_srwiatr as
select mean_wind_speed_mph , substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(mean_wind_speed_mph) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_predkosc_wiatru_na_miesiac
from weather
where zip_code like '94%';

/*odchylenie standardowe*/
select mean_wind_speed_mph, SQUARE(sum(power((mean_wind_speed_mph-sr_predkosc_wiatru_na_miesiac),2))/count(*)) as odchylenie
from v_srwiatr


/*podzialy z widoku i ranking*/
select *
from v_srwiatr
order by sr_predkosc_wiatru_na_miesiac DESC

create view v_srwiatr_ranking as
select rok_i_miesiac, mean_wind_speed_mph,round(sr_predkosc_wiatru_na_miesiac,2),
DENSE_RANK () over (order by sr_predkosc_wiatru_na_miesiac DESC) as ranking
from v_srwiatr;

/*kwartyle*/

select *
from v_srwiatr_ranking
where ranking between 1 AND 5

select *
from v_srwiatr_ranking
where ranking between 6 AND 10

select *
from v_srwiatr_ranking
where ranking between 11 AND 15

select *
from v_srwiatr_ranking
where ranking between 16 AND 20



/*sredni max wiatr*/

select max_wind_Speed_mph, substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(max_wind_Speed_mph) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_max_predkosc_wiatru_na_miesiac
from weather
where zip_code like '94%';



/*sredni max poryw wiatru*/

create view v_srmaxporyw as 
select max_gust_speed_mph, substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac,  
avg(max_gust_speed_mph) over 
	(partition by substring(date,1,2) || '-' || substring(date,-4,4) 
	order by substring(date,1,2) || '-' || substring(date,-4,4)) as sr_max_poryw_wiatru_na_miesiac
from weather
where zip_code like '94%';

/*odchylenie standardowe*/
select max_gust_speed_mph, SQUARE(sum(power((max_gust_speed_mph-sr_max_poryw_wiatru_na_miesiac),2))/count(*)) as odchylenie
from v_srmaxporyw


/*podzialy z widoku i ranking*/
select *
from v_srmaxporyw
order by sr_max_poryw_wiatru_na_miesiac DESC

create view v_pwiatru_ranking as
select rok_i_miesiac, max_gust_speed_mph,round(sr_max_poryw_wiatru_na_miesiac,2),
DENSE_RANK () over (order by sr_max_poryw_wiatru_na_miesiac DESC) as ranking
from v_srmaxporyw;

/*kwartyle*/

select *
from v_pwiatru_ranking
where ranking between 1 AND 5

select *
from v_pwiatru_ranking
where ranking between 6 AND 10

select *
from v_pwiatru_ranking
where ranking between 11 AND 15

select *
from v_pwiatru_ranking
where ranking between 16 AND 20






