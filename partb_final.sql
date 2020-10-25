 USE    db_consumer_panel;
 
 # b.1. How many households do not shop at least once on a 3 month periods.
 # 48
 
CREATE  TABLE hh_month
	SELECT DISTINCT(date_format(TC_date,'%Y-%m-%d')) AS date, hh_id  FROM Trips order by  hh_id;
SELECT * FROM hh_month;

ALTER TABLE hh_month
ADD COLUMN start_time DATETIME;
SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET    start_time = '2003-12-27 00:00:00';

ALTER TABLE hh_month
ADD COLUMN end_time DATETIME;
SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET    end_time = '2004-12-26 00:00:00';

WITH t1 AS
(SELECT DISTINCT  hh_id, (date_format(DATE,'%Y-%m-%d')) AS hh_date
FROM(
	SELECT hh_id,date FROM hh_month
	UNION ALL
	SELECT DISTINCT hh_id, start_time FROM hh_month
	UNION ALL
	SELECT DISTINCT hh_id, end_time FROM hh_month) AS t
    ORDER BY hh_id),
t2 AS
(SELECT *, ROW_NUMBER() OVER (ORDER BY hh_id) AS ID FROM t1),
t3 AS
(SELECT hh_id, hh_date, ID, 1 + ID AS ID_2 FROM  t2 ORDER BY hh_id)
SELECT DISTINCT (t3.hh_id), t3.hh_date, t2.hh_date, datediff(t2.hh_date,t3.hh_date) AS TIME_WINDOW_SIZE FROM t3 
LEFT JOIN  t2
ON t2.ID= t3.ID_2
WHERE datediff(t2.hh_date,t3.hh_date)>90;

# b.2 Among the households who shop at least once a month, which % of them concentrate at least 80% of their grocery expenditure (on average) on single retailer? 

# households shop at least once a month
# 35962

SELECT DISTINCT(hh_id), purchase_times FROM
(SELECT hh_id, COUNT(DISTINCT (MONTH(TC_date))) AS purchase_times
FROM Trips
GROUP BY hh_id
ORDER BY hh_id) AS t
WHERE purchase_times=12;

# single retailer
# 124

CREATE TABLE single_loyalty
SELECT hh_ID,TC_retailer_code
FROM
(SELECT hh_ID,TC_retailer_code, COUNT(purchase_month) AS count_month
FROM 
(SELECT hh_id,TC_retailer_code,purchase_month
FROM
(SELECT A.*,B.spend_monthly_average
FROM 
(SELECT hh_id,TC_retailer_code, MONTH(TC_date) AS purchase_month,SUM(TC_total_spent) AS spend_monthly_retailer
FROM Trips
GROUP BY hh_id,TC_retailer_code,purchase_month
ORDER BY hh_id,purchase_month) AS A
LEFT JOIN
(SELECT hh_id,MONTH(TC_date) AS purchase_month, SUM(TC_total_spent) AS  spend_monthly_average
FROM Trips
GROUP BY hh_id,purchase_month
ORDER BY hh_id,purchase_month) AS B
ON A.hh_id=B.hh_id AND A.purchase_month=B.purchase_month) AS C
WHERE spend_monthly_retailer>0.8*spend_monthly_average) AS D
GROUP BY hh_id,TC_retailer_code) AS E
WHERE count_month=12;
SELECT * FROM  single_loyalty;

#b.2.i. Are their demographics remarkably different? Are these people richer? Poorer?

# details of single loyalty
SELECT Households.* FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id;

# distribution between race
SELECT hh_race AS race,COUNT(hh_id) 
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY hh_race;

# distribution between is_latinx
SELECT hh_is_latinx AS Latinx,COUNT(hh_id) 
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY  hh_is_latinx;

# distribution between size
SELECT hh_size AS Size,COUNT(hh_id) 
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY  hh_size;

# distribution between income
SELECT hh_income AS Income,COUNT(hh_id) AS number
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY  hh_income
ORDER BY number DESC;

# No two family house ‐ condo residents are loyal consumers
# One family house ‐ condo residents just have 1
SELECT hh_residence_type AS Residence,COUNT(hh_id) 
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY  hh_residence_type;


#b.2.ii. What is the retailer that has more loyalists?
SELECT TC_retailer_code,COUNT(hh_id)  AS number
FROM single_loyalty
GROUP BY TC_retailer_code
ORDER BY COUNT(hh_id) DESC;        

#b.2.iii. Where do they live? Plot the distribution by state.

SELECT hh_state AS State, COUNT(*) AS number
FROM
(SELECT hh_state FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY hh_state;

#b.2.  Among the households who shop at least once a month, which % of them concentrate at least 80% of their grocery expenditure (on average)  among 2 retailers?
# 316

CREATE TABLE Loyalism_TOP_2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY hh_id,purchase_month ORDER BY spend_monthly_retailer DESC) AS ID
FROM
(SELECT A.*,B.spend_monthly_average
FROM 
(SELECT hh_id,TC_retailer_code, MONTH(TC_date) AS purchase_month,SUM(TC_total_spent) AS spend_monthly_retailer
FROM Trips
GROUP BY hh_id,TC_retailer_code,purchase_month
ORDER BY hh_id,purchase_month) AS A
LEFT JOIN
(SELECT hh_id,MONTH(TC_date) AS purchase_month, SUM(TC_total_spent) AS  spend_monthly_average
FROM Trips
GROUP BY hh_id,purchase_month
ORDER BY hh_id,purchase_month) AS B
ON A.hh_id=B.hh_id AND A.purchase_month=B.purchase_month) AS C;
SELECT * FROM Loyalism_TOP_2;


CREATE TABLE Loyalism_TOP_2_new
SELECT * FROM Loyalism_TOP_2 WHERE ID=1 OR ID=2;
SELECT * FROM Loyalism_TOP_2_new;

WITH t2 AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY hh_id) AS rank_1
FROM Loyalism_TOP_2_new),
t3 AS
(SELECT hh_id, TC_retailer_code,spend_monthly_retailer,  rank_1-1 AS rank_2 FROM t2)
SELECT t3.hh_id,t2.purchase_month,t2.TC_retailer_code AS retailer_1, t3.TC_retailer_code AS retailer_2, t2.spend_monthly_retailer AS retailerz_spend_1,t3.spend_monthly_retailer AS retailerz_spend_2,t2.spend_monthly_average
FROM
t2
LEFT JOIN
t3
ON  t2.rank_1= t3.rank_2 AND t2.hh_id= t3.hh_id;


CREATE TABLE  Loyalism_TOP_2_CONCAT
WITH t2 AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY hh_id) AS rank_1
FROM Loyalism_TOP_2_new),
t3 AS
(SELECT hh_id, TC_retailer_code,spend_monthly_retailer,  rank_1-1 AS rank_2 FROM t2)
SELECT t3.hh_id,t2.purchase_month,t2.TC_retailer_code AS retailer_1, t3.TC_retailer_code AS retailer_2, t2.spend_monthly_retailer AS retailerz_spend_1,t3.spend_monthly_retailer AS retailerz_spend_2,t2.spend_monthly_average
FROM
t2
LEFT JOIN
t3
ON  t2.rank_1= t3.rank_2 AND t2.hh_id= t3.hh_id;
SELECT * FROM  Loyalism_TOP_2_CONCAT;


CREATE TABLE  Loyalism_TOP_2_ODD
SELECT * FROM
(SELECT *, ROW_NUMBER() OVER() AS rowNumber 
FROM Loyalism_TOP_2_CONCAT) tb1
WHERE tb1.rowNumber % 2 = 1;
SELECT * FROM  Loyalism_TOP_2_ODD;

CREATE TABLE  Loyalism_TOP_2_main
SELECT * FROM Loyalism_TOP_2_ODD WHERE retailerz_spend_1+retailerz_spend_2>0.8*spend_monthly_average;
SELECT * FROM  Loyalism_TOP_2_main;

CREATE TABLE  Loyalism_TOP_2_household
SELECT *
FROM
((SELECT hh_id, purchase_month,retailer_1 AS retailer,retailerz_spend_1 AS retailer_spend,spend_monthly_average
FROM Loyalism_TOP_2_main) 
UNION
(SELECT hh_id, purchase_month,retailer_2 AS retailer,retailerz_spend_2 AS retailer_spend,spend_monthly_average
FROM Loyalism_TOP_2_main)) AS A
ORDER BY  hh_id, purchase_month;
SELECT * FROM  Loyalism_TOP_2_household;

# list of household meet the requirement of Loyalism of 2 retailers.
# 316

CREATE TABLE  Loyalism_TOP_2_household_list
SELECT DISTINCT(A.hh_id)
FROM
(SELECT hh_id
FROM
(SELECT hh_id,COUNT(DISTINCT(purchase_month)) AS count_month
FROM Loyalism_TOP_2_household
GROUP BY hh_id) AS T_1
WHERE count_month=12) AS A
LEFT JOIN
(SELECT hh_id
FROM(
SELECT hh_id,COUNT(DISTINCT(retailer)) AS count_retailer
FROM Loyalism_TOP_2_household
GROUP BY hh_id) AS T_2
WHERE count_retailer=2) AS B
ON A.hh_id=B.hh_id;
SELECT * FROM  Loyalism_TOP_2_household_list;

CREATE TABLE  Loyalism_single_household_list
SELECT hh_ID
FROM
(SELECT hh_ID,TC_retailer_code, COUNT(purchase_month) AS count_month
FROM 
(SELECT hh_id,TC_retailer_code,purchase_month
FROM
(SELECT A.*,B.spend_monthly_average
FROM 
(SELECT hh_id,TC_retailer_code, (MONTH(TC_date)) AS purchase_month,SUM(TC_total_spent) AS spend_monthly_retailer
FROM Trips
GROUP BY hh_id,TC_retailer_code,purchase_month
ORDER BY hh_id,purchase_month) AS A
LEFT JOIN
(SELECT hh_id,(MONTH(TC_date)) AS purchase_month, SUM(TC_total_spent) AS  spend_monthly_average
FROM Trips
GROUP BY hh_id,purchase_month
ORDER BY hh_id,purchase_month) AS B
ON A.hh_id=B.hh_id AND A.purchase_month=B.purchase_month) AS C
WHERE spend_monthly_retailer>0.8*spend_monthly_average) AS D
GROUP BY hh_id,TC_retailer_code) AS E
WHERE count_month=12;
SELECT * FROM  Loyalism_single_household_list;

# final list
CREATE TABLE Loyalism_TOP_2_household_list_final
SELECT DISTINCT(hh_id)
FROM
( SELECT * FROM Loyalism_single_household_list
UNION
SELECT * FROM Loyalism_TOP_2_household_list) AS A;
SELECT * FROM Loyalism_TOP_2_household_list_final;

#detailed information
SELECT Loyalism_TOP_2_household.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Loyalism_TOP_2_household
ON Loyalism_TOP_2_household.hh_id=Loyalism_TOP_2_household_list_final.hh_id;

# detailed information about Top 2 loyalism
SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id;

#b.2.i. Are their demographics remarkably different? Are these people richer? Poorer?

# distribution between race
SELECT hh_race AS race,COUNT(hh_id) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY hh_race
ORDER BY  number DESC;

# distribution between is_latinx
SELECT hh_is_latinx AS Latinx,COUNT(hh_id)  AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_is_latinx
ORDER BY number;

# distribution between size
SELECT hh_size AS Size,COUNT(hh_id) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_size
ORDER BY number DESC;

# distribution between income
SELECT hh_income AS Income,COUNT(hh_id) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_income
ORDER BY number DESC;

# No two family house ‐ condo residents are loyal consumers
# One family house ‐ condo residents just have 1
SELECT hh_residence_type AS Residence,COUNT(hh_id) 
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_residence_type;

#b.2.ii. What is the retailer that has more loyalists?
SELECT retailer,COUNT(DISTINCT(hh_id))  AS number
FROM
(SELECT Loyalism_TOP_2_household.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Loyalism_TOP_2_household
ON Loyalism_TOP_2_household.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY retailer
ORDER BY number DESC;

#b.2.iii. Where do they live? Plot the distribution by state.
SELECT hh_state AS State, COUNT(*) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY hh_state;

#b.3. Plot with the distribution:
#b.3.i. Average number of items purchased on a given month.
select month, avg(quantity)
	from(select  hh_id, month(TC_date) as month, sum(quantity_at_TC_prod_id) as quantity
		from Trips
			right join Purchases
				using(TC_id)
		group by hh_id, month
		order by hh_id) as t8_1
group by month
order by month;

#b.3.ii. Average number of shopping trips per month.
select month, round(avg(trips_amount),2) as avg_trips_amount
from (select hh_id, month(TC_date) as month, count(TC_id) as trips_amount
from Trips
group by hh_id, month
order by hh_id) as t8_2
group by month
order by month;

#b.3.iii. Average number of days between 2 consecutive shopping trips.
DROP TABLE IF EXISTS hh_month;
CREATE  TABLE hh_month
 SELECT date(TC_date) AS date, hh_id  FROM Trips order by  hh_id, date;

ALTER TABLE hh_month
ADD COLUMN start_time DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET    start_time = '2003-12-27';

ALTER TABLE hh_month
ADD COLUMN end_time DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET    end_time = '2004-12-26';

drop table if exists hh_month_plus;
create table hh_month_plus
	(select hh_id, date from hh_month)
	union
	(select distinct hh_id, start_time from hh_month)
	union
	(select distinct hh_id, end_time from hh_month)
	order by hh_id, date;

with t1 as
(select hh_id, date, row_number() over (order by hh_id, date) as index_original from hh_month_plus),
t2 as
(select hh_id, date, index_original + 1 as index_alt from hh_month_plus_1),
 t3 as
 (select t1.hh_id, t1.date as date_bf, t2.date as date_aft
      from t1
      inner join t2
       on index_original = index_alt
       and t1.hh_id = t2.hh_id
      order by t1.hh_id)
select hh_id, avg(datediff(date_bf,date_aft)) as avg_time_interval
 from t3
group by hh_id
order by hh_id;
