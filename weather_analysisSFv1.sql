/*ekstrakcja roku z daty*/

select substring(date,-4,4) as rok
from weather

/*ekstrakcja miesiaca z daty*/

select substring(date,1,2) as miesiac
from weather

/*polaczenie roku i miesiaca*/
select substring(date,1,2) || '-' || substring(date,-4,4) as rok_i_miesiac
from weather


/*duzo lepsza opcja na ekstrakcje daty */

create view v_weather as
select
*,
CASE 
	when substring(date ,4,1) = '/' then substring(date ,5,4)
	when substring(date ,6,1) = '/' then substring(date ,7,4)
	else substring(date ,6,4)
end ||'-'||
case 
	when substring(date, 2,1) = '/' then '0'||substring(date, 1,1)
	else substring(date, 1,2)
end as year_month
from weather

/*temperatura*/
/*srednia maxymalna temperatura na miesiac */

create view v_max_srtemp2 as
select max_temperature_f, year_month,  
avg(max_temperature_f) over 
	(partition by year_month 
	order by year_month) as sr_max_temp_na_miesiac
from v_weather
where zip_code like '94%';


/*odchylenie standardowe*/
select max_temperature_f, SQUARE(sum(power((max_temperature_f-sr_max_temp_na_miesiac),2))/count(*)) as odchylenie
from v_max_srtemp2


/*srednia minimalna temperatura na miesiac (pomijajac lata)*/
create view v_min_srtemp2 as
select min_temperature_f, year_month,  
avg(min_temperature_f) over 
	(partition by year_month 
	order by year_month) as sr_min_temp_na_miesiac
from v_weather
where zip_code like '94%';

/*odchylenie standardowe*/
select min_temperature_f, SQUARE(sum(power((min_temperature_f-sr_min_temp_na_miesiac),2))/count(*)) as odchylenie
from v_min_srtemp2

/*srednia temperatura na miesiac liczac wg sredniej*/

create view v_mean_srtemp2 as
select mean_temperature_f , year_month,  
avg(mean_temperature_f) over 
	(partition by year_month
	order by year_month) as sr_mean_temp_na_miesiac
from v_weather
where zip_code like '94%';

/*odchylenie standardowe*/
select mean_temperature_f, SQUARE(sum(power((mean_temperature_f-sr_mean_temp_na_miesiac),2))/count(*)) as odchylenie
from v_mean_srtemp2

/*podzial na  zbiory*/

select zip_code, year_month, avg(mean_temperature_f) over 
	(partition by year_month
	order by year_month), 
	ntile(4) over 
	(partition by year_month
	order by year_month)
from v_weather
where zip_code like '94%';

/*podzialy z widoku i ranking*/
select *
from v_mean_srtemp2
order by sr_mean_temp_na_miesiac DESC

create view v_temp_ranking4 as
select year_month, mean_temperature_f,round(sr_mean_temp_na_miesiac,2),
DENSE_RANK () over (order by sr_mean_temp_na_miesiac DESC) as ranking
from v_mean_srtemp2;

/*kwartyle*/

select *
from v_temp_ranking4
where ranking between 1 AND 5

select *
from v_temp_ranking4
where ranking between 6 AND 10

select *
from v_temp_ranking4
where ranking between 11 AND 15

select *
from v_temp_ranking4
where ranking between 16 AND 20

/*visibility*/
create view v_meanvisib1 as
select mean_visibility_miles , year_month,  
avg(mean_visibility_miles) over 
	(partition by year_month 
	order by year_month) as sr_mean_visibility_na_miesiac
from v_weather
where zip_code like '94%';

 /*podzialy z widoku i ranking*/
select *
from v_meanvisib1
order by sr_mean_visibility_na_miesiac DESC

create view v_meanvisib3 as
select year_month, mean_visibility_miles,round(sr_mean_visibility_na_miesiac,2),
DENSE_RANK () over (order by sr_mean_visibility_na_miesiac DESC) as ranking
from v_meanvisib1;

/*kwartyle*/

select *
from v_meanvisib3
where ranking between 1 AND 5

select *
from v_meanvisib3
where ranking between 6 AND 10

select *
from v_meanvisib3
where ranking between 11 AND 15

select *
from v_meanvisib3
where ranking between 16 AND 20


select max_visibility_miles _temperature_f , year_month,  
avg(max_visibility_miles) over 
	(partition by year_month
	order by year_month) as sr_max_visibility_na_miesiac
from v_weather
where zip_code like '94%';

select min_visibility_miles , year_month,  
avg(min_visibility_miles) over 
	(partition by year_month 
	order by year_month) as sr_min_visibility_na_miesiac
from v_weather
where zip_code like '94%';

/*opady*/


/*czestotliwosc opadow*/

select count(1), year_month
from v_weather w 
WHERE precipitation_inches>0 and zip_code like '94%'
group by year_month


select count(1), year_month
from v_weather w 
WHERE events = 'Rain' and zip_code like '94%'
group by year_month

/*czestotliwosc mlgy*/

select count(1), year_month
from v_weather w 
WHERE events = 'Fog' and zip_code like '94%'
group by year_month

/*czestotliwosc mgly i deszczu*/

select count(1), year_month
from v_weather w 
WHERE events = 'Fog-Rain' and zip_code like '94%';
group by year_month

/*kod kontrolny*/

select precipitation_inches, year_month
from v_weather w 
where year_month = '2014-01' and precipitation_inches >0 and zip_code like '94%'
order by date; 





/*max opadow*/

select precipitation_inches, year_month,  
max(precipitation_inches) over 
	(partition year_month
	order by year_month) as max_opadow
from v_weather
where zip_code like '94%';

/*srednia opadow*/
create view v_sropadow1 as
select precipitation_inches, year_month,  
avg(precipitation_inches) over 
	(partition by year_month 
	order by year_month) as sr_opadow_na_miesiac
from v_weather
where zip_code like '94%';


/*podzialy z widoku i ranking*/
select *
from  v_sropadow1 
order by sr_opadow_na_miesiac DESC

create view v_sropadow_ranking1 as
select year_month, precipitation_inches,round(sr_opadow_na_miesiac,2),
DENSE_RANK () over (order by sr_opadow_na_miesiac DESC) as ranking
from v_sropadow1;

/*kwartyle*/

select *
from v_sropadow_ranking1
where ranking between 1 AND 5

select *
from v_sropadow_ranking1
where ranking between 6 AND 10

select *
from v_sropadow_ranking1
where ranking between 11 AND 15

select *
from v_sropadow_ranking1
where ranking between 16 AND 20



/*wiatr*/


/*sredni wiatr*/ 
create view v_srwiatr1 as
select mean_wind_speed_mph , year_month,  
avg(mean_wind_speed_mph) over 
	(partition by year_month 
	order by year_month) as sr_predkosc_wiatru_na_miesiac
from v_weather
where zip_code like '94%';

/*odchylenie standardowe*/
select mean_wind_speed_mph, SQUARE(sum(power((mean_wind_speed_mph-sr_predkosc_wiatru_na_miesiac),2))/count(*)) as odchylenie
from v_srwiatr1


/*podzialy z widoku i ranking*/
select *
from v_srwiatr1
order by sr_predkosc_wiatru_na_miesiac DESC

create view v_srwiatr_ranking2 as
select year_month, mean_wind_speed_mph,round(sr_predkosc_wiatru_na_miesiac,2),
DENSE_RANK () over (order by sr_predkosc_wiatru_na_miesiac DESC) as ranking
from v_srwiatr1;

/*kwartyle*/

select *
from v_srwiatr_ranking2
where ranking between 1 AND 5

select *
from v_srwiatr_ranking2
where ranking between 6 AND 10

select *
from v_srwiatr_ranking2
where ranking between 11 AND 15

select *
from v_srwiatr_ranking2
where ranking between 16 AND 20



/*sredni max wiatr*/

select max_wind_Speed_mph, year_month,  
avg(max_wind_Speed_mph) over 
	(partition by year_month
	order by year_month) as sr_max_predkosc_wiatru_na_miesiac
from v_weather
where zip_code like '94%';



/*sredni max poryw wiatru*/

create view v_srmaxporyw1 as 
select max_gust_speed_mph, year_month,  
avg(max_gust_speed_mph) over 
	(partition by year_month
	order by year_month) as sr_max_poryw_wiatru_na_miesiac
from v_weather
where zip_code like '94%';

/*odchylenie standardowe*/
select max_gust_speed_mph, SQUARE(sum(power((max_gust_speed_mph-sr_max_poryw_wiatru_na_miesiac),2))/count(*)) as odchylenie
from v_srmaxporyw1


/*podzialy z widoku i ranking*/
select *
from v_srmaxporyw1
order by sr_max_poryw_wiatru_na_miesiac DESC

create view v_pwiatru_ranking1 as
select year_month, max_gust_speed_mph,round(sr_max_poryw_wiatru_na_miesiac,2),
DENSE_RANK () over (order by sr_max_poryw_wiatru_na_miesiac DESC) as ranking
from v_srmaxporyw1;

/*kwartyle*/

select *
from v_pwiatru_ranking1
where ranking between 1 AND 5

select *
from v_pwiatru_ranking1
where ranking between 6 AND 10

select *
from v_pwiatru_ranking1
where ranking between 11 AND 15

select *
from v_pwiatru_ranking1
where ranking between 16 AND 20




