-- Monday Coffee -- Data Analysis
select * from monday_coffee_db.city;
select * from monday_coffee_db.customers;
select * from monday_coffee_db.products;
select * from monday_coffee_db.sales;

-- Reports and Data Analysis
-- Q 1. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name, 
    round((population * 0.25)/1000000,2) as coffee_consumers_in_millions, 
    city_rank
FROM
    monday_coffee_db.city
ORDER BY population desc;

-- Q 2. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    ci.city_name, SUM(s.total) AS total_revenue
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON ci.city_id = c.city_id
WHERE
    EXTRACT(YEAR FROM s.sale_date) = 2023
        AND EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q 3. Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    p.product_name, COUNT(s.sale_id) AS total_orders
FROM
    monday_coffee_db.products AS p
        LEFT JOIN
    monday_coffee_db.sales AS s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;

-- Q 4. Average Sales Amount per City
-- What is the average sales amount per customer in each city?
-- city and total sale
-- total unique customers in the city

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2) AS average_sale_per_customer
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q 5. City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total_current_customers, estimated coffee consumers(25%)


WITH city_table as
(SELECT 
    city_name, round((population * 0.25) / 1000000, 2) as coffee_consumers
    from monday_coffee_db.city),
customers_table as
(SELECT 
    ci.city_name,
	COUNT(DISTINCT c.customer_id) AS unique_customers
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name)
select 
city_table.city_name, city_table.coffee_consumers, customers_table.unique_customers
from city_table
join
customers_table  
on customers_table.city_name = city_table.city_name

-- Q 6. Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * from 
(SELECT 
    ci.city_name,
    p.product_name,
    COUNT(s.sale_id) AS total_orders,
    dense_rank() over(partition by ci.city_name ORDER BY COUNT(s.sale_id) desc) as ranking
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.products AS p ON s.product_id = p.product_id
        JOIN
    monday_coffee_db.customers AS c ON c.customer_id = s.customer_id
        JOIN
    monday_coffee_db.city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name , p.product_name
-- ORDER BY ci.city_name , total_orders desc;
)
AS t1
where ranking <= 3

-- Q 7. Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products? 

-- Select * from monday_coffee_db.products;

SELECT 
    ci.city_name, count(distinct c.customer_id) as unique_customers
FROM
    monday_coffee_db.city AS ci
        LEFT JOIN
    monday_coffee_db.customers AS c ON c.city_id = ci.city_id
        JOIN
    monday_coffee_db.sales AS s ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.products AS p ON p.product_id = s.product_id
where s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
group by ci.city_name
order by unique_customers desc;

-- Q 8. Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
-- Conclusions
WITH city_table
AS
(
SELECT 
    ci.city_name,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2) AS average_sale_per_customer
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_customers DESC
),
city_rent
AS
(
SELECT city_name, estimated_rent
from monday_coffee_db.city
)

SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_customers,
    ct.average_sale_per_customer,
    ROUND(cr.estimated_rent / ct.total_customers,
            2) AS average_rent_per_customers
FROM
    city_rent AS cr
        JOIN
    city_table AS ct ON cr.city_name = ct.city_name
    order by ct.average_sale_per_customer desc;
    -- average_rent_per_customers desc;
    
-- Q 9. Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city

WITH 
monthly_sales
AS
(
SELECT 
    ci.city_name,
    EXTRACT(MONTH FROM sale_date) AS month,
    EXTRACT(YEAR FROM sale_date) AS year,
    SUM(s.total) AS total_sale
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name , month , year
ORDER BY ci.city_name , year, month
),
growth_ratio
AS
(
SELECT 
    city_name, month, year, total_sale AS cr_month_sale, lag(total_sale, 1) over(partition by city_name order by year, month) as last_month_sale
FROM
    monthly_sales
)
SELECT 
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND((cr_month_sale - last_month_sale) / last_month_sale * 100,
            2) AS growth_ratio
FROM
    growth_ratio
WHERE
    last_month_sale IS NOT NULL
    
-- Q 10. Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(
SELECT 
    ci.city_name,
    SUM(s.total) as total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2) AS average_sale_per_customer
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC
),
city_rent
AS
(
SELECT 
    city_name,
    estimated_rent,
    ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer
FROM
    monday_coffee_db.city
)

SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_customers,
    cr.estimated_coffee_consumer,
    ct.average_sale_per_customer,
    ROUND(cr.estimated_rent / ct.total_customers,
            2) AS average_rent_per_customers
FROM
    city_rent AS cr
        JOIN
    city_table AS ct ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC;

/*
--Recommendation
After analyzing the data, the recommended top three cities for new store openings are:

City 1: Pune
	1. Average rent per customer is very low.
	2. Highest total revenue.
	3. Average sales per customer is also high.

City 2: Delhi
	1. Highest estimated coffee consumers at 7.7 million.
	2. Highest total number of customers, which is 68.
	3. Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1. Highest number of customers, which is 69.
	2. Average rent per customer is very low at 156.
	3. Average sales per customer is better at 11.6k.
*/
