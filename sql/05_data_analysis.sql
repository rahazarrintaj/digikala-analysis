SELECT *
FROM orders
;

SELECT count(DISTINCT ID_Order)
FROM orders;

-- ---------------------------------------------------------------------- 1. SALES TREND ------------------------------------------------------------------------------------

SELECT *
FROM orders
;

-- Monthly sales (روند ماهانه)
WITH monthly_sales AS(
   SELECT year(DateTime_CartFinalize) as years, 
   month(DateTime_CartFinalize) as months, 
   sum(Amount_Gross_Order * Quantity_item) as current_sales, 
   sum(Quantity_item) as current_orders
   FROM orders
   WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
   GROUP BY year(DateTime_CartFinalize), month(DateTime_CartFinalize)
),

monthly_trend AS(

  SELECT *, LAG(current_sales) over(ORDER BY years, months) as prev_month_sales,
  LAG(current_orders) over(ORDER BY years, months) as prev_month_orders
  FROM monthly_sales
)

SELECT *,
 round( (current_sales - prev_month_sales) / nullif(prev_month_sales, 0) * 100 , 2) as sales_growth_pcn,
 round( (current_orders - prev_month_orders) / nullif(prev_month_orders, 0) * 100 , 2) as orders_growth_pcn
FROM monthly_trend
;


-- Yearly growth (رشد سال به سال)
WITH monthly_sales AS(
   SELECT year(DateTime_CartFinalize) as years, month(DateTime_CartFinalize) as months,
   sum(Amount_Gross_Order * Quantity_item) as current_sales,
   sum(Quantity_item) as current_orders
FROM orders
WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
GROUP BY year(DateTime_CartFinalize), month(DateTime_CartFinalize)
ORDER BY year(DateTime_CartFinalize), month(DateTime_CartFinalize)
),

sales_comparison AS(
   SELECT years, months, current_sales, current_orders,
   LAG(current_sales) OVER (PARTITION BY months ORDER BY years) as prev_year_sales,
   LAG(current_orders) OVER (PARTITION BY months ORDER BY years) as prev_year_orders
   FROM monthly_sales
)

SELECT *, current_sales - prev_year_sales as sales_diff,
round( (current_sales - prev_year_sales) / prev_year_sales * 100, 2) as sales_growth_pct,
current_orders - prev_year_orders as orders_diff,
round( (current_orders - prev_year_orders) / prev_year_orders * 100, 2) as orders_growth_pcte
FROM sales_comparison
WHERE prev_year_sales IS NOT NULL
ORDER BY years, months
;


-- seasonal comparison (فصل بندی)
WITH quarterly_sales AS (
    SELECT year(DateTime_CartFinalize) AS years, quarter(DateTime_CartFinalize) AS quarters,
        sum(Amount_Gross_Order * Quantity_item) AS total_sales,
        sum(Quantity_item) AS total_orders
    FROM orders
    WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
    GROUP BY year(DateTime_CartFinalize), quarter(DateTime_CartFinalize)
)

SELECT *
FROM quarterly_sales
ORDER BY years, quarters;


-- Seasonal growth (فصل بندی)
with monthly_sales AS (
    SELECT date_format(DateTime_CartFinalize, '%Y-%m-01') as month_start,
    sum(Amount_Gross_Order * Quantity_item) AS current_sales,
	sum(Quantity_item) AS current_orders
    FROM orders
    WHERE DateTime_CartFinalize >= '2013-10-01' AND DateTime_CartFinalize < '2018-12-01'
    GROUP BY date_format(DateTime_CartFinalize, '%Y-%m-01')
),

moving_avg AS(
    SELECT *, 
    avg(current_sales) OVER(ORDER BY month_start ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING) as avg1,
    count(*) OVER(ORDER BY month_start ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING) as count1,
    avg(current_sales) OVER(ORDER BY month_start ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING) as avg2,
    count(*) OVER(ORDER BY month_start ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING) as count2
    FROM monthly_sales
    ORDER BY month_start
),

seasonal_ratio AS(
    SELECT *, 
    (avg1 + avg2)/ 2 as trend
    FROM moving_avg
    ORDER BY month_start
),

monthly_ratio AS(
    SELECT month(month_start) as month_number, 
    monthname(month_start) as month_name,
    current_sales / nullif(trend, 0) as seasonal_ratio,
    YEAR(month_start) AS year
    FROM seasonal_ratio
    WHERE count1 = 12 AND count2 = 12
    ORDER BY month_start
)

SELECT month_number, month_name,
round(avg(seasonal_ratio), 4) as seasonal_index,
round((avg(seasonal_ratio) - 1) * 100 , 2) as deviation_percentage,
count(*) as number_of_observations
FROM monthly_ratio
GROUP BY month_number, month_name
ORDER BY month_number, month_name
;


-- ---------------------------------------------------------------------- 2. CITIES TREND ------------------------------------------------------------------------------------


-- cities with most orders: تهران، مشهد، اصفهان are first three
SELECT city_name_fa, count(DISTINCT ID_Order) as order_num
FROM orders
GROUP BY city_name_fa
ORDER BY order_num desc
;


-- percentage of orders in each city: 54.18% of orders are from tehran, the next highest mashhad is 3.01%
WITH number_of_orders AS (
SELECT city_name_fa, count(DISTINCT ID_Order) as order_num
FROM orders
GROUP BY city_name_fa
ORDER BY order_num desc
) 
SELECT *,
round(order_num / sum(order_num) OVER() * 100, 2) as order_pct
FROM number_of_orders
;

-- first 10 city's share of total orders : 72.57%, first 22 cities make up 80.20% of total orders
WITH number_of_orders AS (
SELECT city_name_fa, count(DISTINCT ID_Order) as order_num
FROM orders
GROUP BY city_name_fa
ORDER BY order_num desc
),

order_pct AS(
SELECT city_name_fa, order_num,
round(order_num / sum(order_num) OVER() * 100, 2) as order_pct
FROM number_of_orders
LIMIT 10
)
SELECT *, sum(order_pct) OVER(ORDER BY order_num) as cumalative_sum_pct
FROM order_pct
ORDER BY order_pct DESC
;


-- catagorizing cities with less than 10 orders, 467 cities with less than 10 orders
SELECT count(DISTINCT ID_Order) as order_num,
CASE
 WHEN count(DISTINCT ID_Order) < 10 THEN  'سایر' 
 ELSE city_name_fa
END AS city_name
FROM orders
GROUP BY city_name_fa
ORDER BY order_num desc;

-- Tehran's share over the years: rises starting with 0.13% in 2013 to 34.41% in 2018
WITH number_of_orders AS (
SELECT year(DateTime_CartFinalize) as years, count(DISTINCT ID_Order) as total_orders,
count( DISTINCT CASE
WHEN city_name_fa = 'تهران' THEN ID_Order
        END
) as tehran_orders
FROM orders 
WHERE year(DateTime_CartFinalize) BETWEEN 2014 AND 2018
GROUP BY year(DateTime_CartFinalize)
) 
SELECT *,
round(tehran_orders / total_orders * 100, 2) as order_pct
FROM number_of_orders
;


-- ---------------------------------------------------------------------- 3. Order Value ------------------------------------------------------------------------------------

-- 1)checking if the total_sales is Amount_Gross_Order*Quantity_item
SELECT sum(Order_amount) as total_sales,
count(*) as total_orders
FROM(
SELECT ID_Order, sum(Amount_Gross_Order*Quantity_item) as Order_amount
FROM orders
GROUP BY ID_Order
) as t
;

SELECT sum(Amount_Gross_Order * Quantity_item) as total_sales, count(DISTINCT ID_Order) as total_orders
FROM orders;


-- 2)3 rows with Amount_Gross_Order=0 will not be evaluated
SELECT * 
FROM orders
WHERE Amount_Gross_Order = 0;


-- 3)looking for outliers

-- 3)mean = 1599035.7678939586
WITH order_amounts AS(
   SELECT ID_Order,
   sum(Amount_Gross_Order * Quantity_item) as order_amount
   FROM orders
   WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
   GROUP BY ID_Order
)
SELECT avg(order_amount) as mean_order_value
FROM order_amounts
;


-- 3)median = 370000   (mean > meadia --> orders with high amounts made the avg go up)
WITH order_amounts AS(
   SELECT ID_Order,
   sum(Amount_Gross_Order * Quantity_item) as order_amount
   FROM orders
   WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
   GROUP BY ID_Order
),

row_num AS(
  SELECT order_amount,
  ROW_NUMBER() OVER(ORDER BY order_amount) as row_num,
  count(*) OVER() as total_orders
  FROM order_amounts
)

SELECT avg(order_amount) as median_order_value
FROM row_num
WHERE row_num IN(floor((total_orders+1)/2),
ceil((total_orders+1)/2))
;



-- 4)PERCENTILES
WITH order_amounts AS(
   SELECT ID_Order,
   sum(Amount_Gross_Order * Quantity_item) as order_amount
   FROM orders
   WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
   GROUP BY ID_Order
),

row_num AS(
  SELECT order_amount,
  ROW_NUMBER() OVER(ORDER BY order_amount) as row_num,
  count(*) OVER() as total_orders
  FROM order_amounts
),

percentiles AS(
  SELECT avg(CASE WHEN row_num IN
            (floor((total_orders + 1)* 0.25),
            ceil((total_orders + 1)* 0.25))
            THEN order_amount
            END) AS P25,
            avg(CASE WHEN row_num IN
            (floor((total_orders + 1)* 0.5),
            ceil((total_orders + 1)* 0.5))
            THEN order_amount
            END) AS P50, 
            avg(CASE WHEN row_num IN
            (floor((total_orders + 1)* 0.75),
            ceil((total_orders + 1)* 0.75))
            THEN order_amount
            END) AS P75, 
            avg(CASE WHEN row_num IN
            (floor((total_orders + 1)* 0.90),
            ceil((total_orders + 1)* 0.90))
            THEN order_amount
            END) AS P90, 
            avg(CASE WHEN row_num IN
            (floor((total_orders + 1)* 0.99),
            ceil((total_orders + 1)* 0.99))
            THEN order_amount
            END) AS P99, 
            max(order_amount) as max_order_amount
   FROM row_num

)
SELECT *
FROM percentiles
;


-- 5)share of 10 top orders: 66.12
WITH order_amounts AS(
   SELECT ID_Order,
   sum(Amount_Gross_Order * Quantity_item) as order_amount
   FROM orders
   WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
   GROUP BY ID_Order
),

row_num AS(
  SELECT order_amount,
  ROW_NUMBER() OVER(ORDER BY order_amount DESC) as row_num,
  count(*) OVER() as total_orders
  FROM order_amounts
),

top_10_share AS(
  SELECT *
   FROM row_num
   WHERE row_num <= ceil(total_orders * 0.10)

)
SELECT sum(order_amount) as top_10_sales,
(SELECT sum(order_amount) FROM order_amounts) as total_sales,
round(sum(order_amount) / (SELECT sum(order_amount) FROM order_amounts) * 100, 2) as top_10_sales_share
FROM top_10_share
;



-- 6)median and mean over months
WITH order_amounts AS(
   SELECT ID_Order,
   date_format(min(DateTime_CartFinalize), '%Y-%m-01') as month_start,
   sum(Amount_Gross_Order * Quantity_item) as order_amount
   FROM orders
   WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
   GROUP BY ID_Order
),

monthly_rank AS(
  SELECT month_start, order_amount,
  ROW_NUMBER() OVER(PARTITION BY month_start ORDER BY order_amount) as row_num,
  count(*) OVER(PARTITION BY month_start) as monthly_orders
  FROM order_amounts
)

SELECT month_start, avg(order_amount) as mean_order_value,
avg(CASE WHEN row_num IN 
(floor((monthly_orders+1)/2),
ceil((monthly_orders+1)/2)) THEN order_amount
END) as median_order_value
FROM monthly_rank
GROUP BY month_start
ORDER BY month_start
;


-- 7)median and mean of TEHRAN compared with other cities
WITH order_amounts AS(
   SELECT ID_Order,
   CASE
            WHEN MAX(
                CASE WHEN city_name_fa = 'تهران' THEN 1 ELSE 0 END
            ) = 1 THEN 'Tehran'
            ELSE 'Other Cities'
        END AS city_group,
   sum(Amount_Gross_Order * Quantity_item) as order_amount
   FROM orders
   WHERE date(DateTime_CartFinalize) BETWEEN '2013-10-01' AND '2018-11-30'
   GROUP BY ID_Order
),

city_group_rank AS(
  SELECT city_group, order_amount,
  ROW_NUMBER() OVER(PARTITION BY city_group ORDER BY order_amount) as row_num,
  count(*) OVER(PARTITION BY city_group) as city_group_orders
  FROM order_amounts
)

SELECT city_group, avg(order_amount) as mean_order_value,
avg(CASE WHEN row_num IN 
(floor((city_group_orders+1)/2),
ceil((city_group_orders+1)/2)) THEN order_amount
END) as median_order_value,
count(*) as total_orders
FROM city_group_rank
GROUP BY city_group
;








