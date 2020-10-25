 USE    db_consumer_panel;

# a.1. How many store shopping trips are recorded in your database?
# 7596145
SELECT COUNT(*) FROM Trips;
SELECT COUNT(TC_id) FROM Trips;

# a.2. How many households appear in your database?
# 39577
SELECT COUNT(DISTINCT hh_id) FROM Households;

# a.3. How many stores of different retailers appear in our data base?
# 26406
SELECT SUM(num_ret_store) FROM (SELECT TC_retailer_code, COUNT(DISTINCT TC_retailer_code_store_code) AS num_ret_store 
FROM Trips WHERE TC_retailer_code_store_code != "0"
GROUP BY TC_retailer_code) AS A;

# a.4. How many different products are recorded?
# 4231283
SELECT COUNT(DISTINCT prod_id)  FROM Products;

# a.4.i. How many products per category and products per module
# products per category: 118 rows returned
SELECT group_at_prod_id, COUNT(DISTINCT prod_id) AS num_pro_cat FROM Products WHERE group_at_prod_id IS NOT NULL GROUP BY group_at_prod_id; 

# products per module: 1224 rows returned
SELECT module_at_prod_id, COUNT(DISTINCT prod_id) AS num_pro_mod FROM Products WHERE module_at_prod_id IS NOT NULL GROUP BY module_at_prod_id;

#a.4.ii. Plot the distribution of products and modules per department
SELECT department_at_prod_id, COUNT(DISTINCT prod_id) AS num_pro_dep
FROM Products WHERE department_at_prod_id IS NOT NULL
GROUP BY department_at_prod_id;

SELECT department_at_prod_id, COUNT(DISTINCT module_at_prod_id) AS num_mod_dep
FROM Products WHERE department_at_prod_id IS NOT NULL
GROUP BY department_at_prod_id;

# a.5.i. Total transactions and transactions realized under some kind of promotion.
# total transactions from table Trips: 7596145
# total transactions from table Purchases: 5651255
# transactions realized under some kind of promotion: 874873
SELECT COUNT(DISTINCT(TC_id))  FROM Trips;
SELECT COUNT(DISTINCT(TC_id)) FROM Purchases;
SELECT COUNT(DISTINCT(TC_id)) FROM Purchases WHERE coupon_value_at_TC_prod_id != "0";