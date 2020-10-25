USE    db_consumer_panel;

#c.3.i. What are the product categories that have proven to be more “Private labelled”
SELECT department_at_prod_id, COUNT(brand_at_prod_id) AS num_priv_prod 
FROM (SELECT * FROM Products WHERE brand_at_prod_id = 'CTL BR') AS A 
WHERE department_at_prod_id IS NOT NULL 
GROUP BY department_at_prod_id
ORDER BY num_priv_prod DESC;

#c.3.ii. Is the expenditure share in Private Labeled products constant across months?
create table c_3_2
with 
-- basic processes with tables
t1 as
(select TC_id, prod_id, quantity_at_TC_prod_id as quantity from Purchases),
t2 as
(select brand_at_prod_id as brand, prod_id from Products where brand_at_prod_id = "CTL BR" ),
t3 as
(select TC_id, month(TC_date) as month from Trips),

t4 as 
(select month, quantity, prod_id 
	from t1
     inner join t3
     using(TC_id)),
     
-- CTL BR's total monthly quantity
t5 as 
(select month , sum(quantity) as quantity_BR
	from t4
	 inner join t2
     using(prod_id)
 group by month),
     
-- all products' total quantity
t6 as
(select month, sum(quantity) as quantity_total
	from t4
 group by month),
 t7 as 
 (select t5.month as month, quantity_BR, quantity_total
	from t5
    inner join t6
    using(month))

-- calculate ratio
select  month, quantity_BR/quantity_total as quantity_share
	from t7 
order by month;

select * from c_3_2;

select hh_id, TC_id, month(TC_date) as month , TC_total_spent from Trips;



#c.3.iii. Cluster households in three income groups, Low, Medium and High. Report the average monthly expenditure on grocery. Study the % of private label share in their monthly expenditures. Use visuals to represent the intuition you are suggesting.
create table c_3_31
with 
-- basic processes with tables
t1 as
(select TC_id, prod_id, total_price_paid_at_TC_prod_id as total_price_prod from Purchases),
t2 as
(select brand_at_prod_id as brand, prod_id from Products where brand_at_prod_id = "CTL BR" ),
t3 as
(select hh_id, TC_id, month(TC_date) as month , TC_total_spent from Trips),

-- cluster hh in 3 groups
t8 as
(select hh_id, hh_income, 1*(hh_income<=10)+2*(hh_income>10 and hh_income<=20)+3*(hh_income>20) as income_group
	from households),

t9 as
(select income_group, month, TC_id, TC_total_spent
	from t3
		inner join t8
        using(hh_id)),
        
-- monthly total expenditure
t10 as 
(select income_group, month, sum(TC_total_spent) as monthly_spent
	from t9
    group by income_group, month
    order by income_group, month),

-- only CTL BR
t11 as
(select TC_id, total_price_prod 
	from t1
    inner join t2
    using(prod_id)),
t12 as
(select income_group, month, sum(total_price_prod) as priv_spent
	from t11
		inner join t9
		using(TC_id)
 group by income_group, month
 order by income_group, month)
 select t12.income_group, t12.month, priv_spent/monthly_spent as prive_share
	from t12
		inner join t10
        on t12.income_group = t10.income_group
        and t12.month = t10.month
order by income_group, month;

select * from c_3_31;

drop table if exists c_3_32;
create table c_3_32
with 
-- basic processes with tables
t1 as
(select TC_id, prod_id, total_price_paid_at_TC_prod_id as price_prod from Purchases),
t2 as
(select prod_id from Products 
	where department_at_prod_id like '%GROCERY%'),
t3 as
(select hh_id, TC_id, month(TC_date) as month from Trips),

-- cluster hh in 3 groups
t8 as
(select hh_id, 1*(hh_income<=10)+2*(hh_income>10 and hh_income<=20)+3*(hh_income>20) as income_group from households),

t9 as
(select hh_id, income_group, month, TC_id
	from t3
		inner join t8
        using(hh_id)),

-- only groceries
t11 as
(select TC_id, price_prod 
	from t1
    inner join t2
    using(prod_id)),

-- distinct hh_id, and then income_group can stands for hh_id
t12 as
(select month, hh_id, income_group, sum(price_prod) as sum_price_prod
	from t11
		inner join t9
		using(TC_id)
 group by month,hh_id
 order by month,hh_id)
 
-- monthly spent on grocery products of each group
select month, income_group, avg(sum_price_prod) as groc_spent
	from t12
 group by month,income_group
 order by month,income_group;

 -- average monthly groceries purchased of each group
/*
select income_group,avg(groc_spent) as avg_groc_spent
	from t13
group by income_group
order by income_group;
*/

select * from c_3_32;