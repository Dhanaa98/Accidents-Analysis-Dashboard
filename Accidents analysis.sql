		-- Data Cleaning

select * from thai_accidents;

-- 1. Remove Duplications
-- 2. Standardize the data
-- 3. Null or Blank values
-- 4. Remove any columns


	-- 1. Remove Duplications

create table thai_accidents_staging
like thai_accidents;
insert thai_accidents_staging
select * from thai_accidents;

select * from thai_accidents_staging;

with duplicate_cte as 
(select *, 
row_number()
over(
partition by accident_code, accident_date, province, vehicle_type, accident_type)as row_num
from thai_accidents_staging)
select * from duplicate_cte where row_num >1;

-- No duplicates found


	-- 2. Standardizing data

select accident_date,
str_to_date(accident_date, '%d-%b-%y')
from thai_accidents_staging;

update thai_accidents_staging
set accident_date = str_to_date(accident_date, '%d-%b-%y');

alter table thai_accidents_staging
modify column accident_date date;

select report_date,
str_to_date(report_date, '%d-%b-%y')
from thai_accidents_staging;

update thai_accidents_staging
set report_date = str_to_date(report_date, '%d-%b-%y');

alter table thai_accidents_staging
modify column report_date date;

	-- 3. Null or Blank values

select * from thai_accidents_staging
where accident_code is null or
    accident_date is null or
    accident_time is null or
    report_date is null or
    report_time is null or
    province is null or
    agency is null or
    vehicle_type is null or
    presumed_cause is null or
    accident_type is null or
    number_of_vehicles_involved is null or
    number_of_fatalities is null or
    number_of_injuries is null or
    weather_condition is null or
    latitude is null or
    longitude is null or
    road_description is null or
    slope_description is null;
    
-- No null or blank values found


	-- 4. Remove any columns

-- No columns to be removed



		-- Exploratory Data Analysis

select min(accident_date), max(accident_date)
from thai_accidents_staging;

-- Total accidents by year
select year(accident_date), count(*) as count
from thai_accidents_staging
group by year(accident_date)
order by year(accident_date) ;

-- Total accidents by month
with rolling_total as (
select substring(accident_date, 1,7) as month, count(accident_code) as total_accidents 
from thai_accidents_staging
group by month
order by 1 asc)
select month, total_accidents, sum(total_accidents) over(order by month) as rolling_total
from rolling_total;

-- Total number of accidents 
select 
count(accident_code)
from thai_accidents_staging;

-- Top 5 provinces ranked with the most number of accidents over the years
with province_year (province, year, total_accidents)as(
select province, year(accident_date), count(accident_code) as total_accidents
from thai_accidents_staging
group by province, year(accident_date)
), province_year_rank as
(select *, 
dense_rank() over(partition by year order by total_accidents desc) as ranking
from province_year)
select * from province_year_rank
where ranking <= 5;

-- Number of accidents resulted in fatalities
select count(*)
from thai_accidents_staging
where number_of_fatalities > 0;

select *
from thai_accidents_staging
order by(number_of_fatalities) desc;

-- Total number of fatalities and injuries
select 
sum(number_of_fatalities), sum(number_of_injuries)
from thai_accidents_staging;

-- Max number of fatalities from an accident 
select 
max(number_of_fatalities)
from thai_accidents_staging;

-- Avg number of fatalities and injuries
select 
avg(number_of_fatalities),
avg(number_of_injuries)
from thai_accidents_staging;

-- Peak hours for accidents
select hour(str_to_date(accident_time,'%H:%i:%s')), count(*) as count
from thai_accidents_staging
group by hour(str_to_date(accident_time,'%H:%i:%s'))
order by count desc;

-- Top 5 causes for the accidents
select presumed_cause, count(*) as count
from thai_accidents_staging
group by presumed_cause
order by count desc
limit 5;

-- Average delay between accident occurence and reporting
select avg(datediff(report_date, accident_date))
from thai_accidents_staging;

select avg(datediff(report_date, accident_date))
from thai_accidents_staging
where number_of_fatalities > 0;

-- Causes of accidents with time of day
select presumed_cause, hour(accident_time) as hour, 
count(*) as count
from thai_accidents_staging
group by presumed_cause, hour(accident_time)
order by hour(accident_time), count desc;

-- Effect of road condition with the occurence of accidents
select road_description, count(*) as count
from thai_accidents_staging
group by road_description
order by count desc;

-- Combined effect of weather and road conditions on accident severity
select weather_condition, road_description, 
avg(number_of_fatalities) as avg_fatalities,
avg(number_of_injuries) as avg_injuries
from thai_accidents_staging
group by weather_condition, road_description
order by avg_fatalities desc, avg_injuries desc;

