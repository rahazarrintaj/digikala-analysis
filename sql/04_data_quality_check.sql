SELECT * 
FROM orders;

DESCRIBE orders;

-- COUNT(DISTINCT ID_Order) = '197631' , COUNT(DISTINCT ID_Customer) = '151634',  COUNT(DISTINCT ID_Item) = '95232'
SELECT COUNT(DISTINCT ID_Order), COUNT(DISTINCT ID_Customer),  COUNT(DISTINCT ID_Item) 
FROM orders;

-- each order has more than one row (Amount_Gross_Order for each order with i rows: Quantity_item_i*Amount_Gross_Order_i)?
SELECT  ID_Order, count(*)
FROM orders
GROUP BY ID_Order
HAVING count(*) > 1
;

-- Does Amount_Gross_Order behave like a line total or a unit price?
-- Compare the same item in the same year: rows with Quantity = 2 vs Quantity = 1
-- --->   فروش = SUM(Amount_Gross_Order * Quantity_item)

WITH item_stats AS (
    SELECT
        ID_Item,
        YEAR(DateTime_CartFinalize)                      AS yr,
        AVG(CASE WHEN Quantity_item = 1 THEN Amount_Gross_Order END) AS avg_q1,
        AVG(CASE WHEN Quantity_item = 2 THEN Amount_Gross_Order END) AS avg_q2,
        SUM(Quantity_item = 1)                           AS n_q1,
        SUM(Quantity_item = 2)                           AS n_q2
    FROM orders
    WHERE Amount_Gross_Order > 0                         -- drop the 3 zero-amount rows
    GROUP BY ID_Item, YEAR(DateTime_CartFinalize)
    HAVING n_q1 >= 1 AND n_q2 >= 1                       -- only items seen with both quantities
),
ratios AS (
    SELECT ID_Item, yr, avg_q2 / NULLIF(avg_q1, 0) AS ratio
    FROM item_stats
),
ranked AS (
    SELECT
        ratio,
        ROW_NUMBER() OVER (ORDER BY ratio) AS rn,
        COUNT(*)     OVER ()               AS cnt
    FROM ratios
    WHERE ratio IS NOT NULL
)
SELECT
    COUNT(*)                                                           AS n_pairs,
    ROUND(AVG(CASE WHEN rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2))
                   THEN ratio END), 3)                                 AS median_ratio,
    ROUND(AVG(ratio BETWEEN 0.8 AND 1.2), 3)                           AS share_near_1,
    ROUND(AVG(ratio BETWEEN 1.8 AND 2.2), 3)                           AS share_near_2
FROM ranked;

-- Amount_Gross_Order is different in each instance
SELECT * 
FROM orders
WHERE ID_Order = '9916301';

-- alter DateTime_CartFinalize column to datetime
/*ALTER TABLE orders
MODIFY DateTime_CartFinalize DATETIME NOT NULL;*/


-- '2013-09-27 12:03:00' to '2018-12-11 04:47:23' ORDERS timeline
SELECT min(DateTime_CartFinalize) as min, max(DateTime_CartFinalize) as max
FROM orders
;

-- number of orders for each month (ascending through time)
SELECT year(DateTime_CartFinalize) as order_year, month(DateTime_CartFinalize) as order_month, count(DISTINCT ID_Order) as number_of_orders
FROM orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month
;
-- starting from 2013-9 : 6, 73, 90, 116, 140, 148  in the end: 2018-10 to 2018-12 : 5485, 5933, 2154 (analysis from 2013-10 to 2018-11 (bcs the days of the first and last months are not complete))

-- we have 906 cities
SELECT count(DISTINCT city_name_fa)
FROM orders
;


-- 2369 rows with more than one ID_order
SELECT count(ID_Order) - count(DISTINCT ID_Order)
FROM orders
;

-- number of unique cities: 906
SELECT count(DISTINCT city_name_fa)
FROM orders
;

-- number of customers with more than one order: 27536,  with just one order: 124098
SELECT sum( CASE
WHEN order_count > 1 THEN 1
ELSE 0
END
) as more_than_one_order,
sum( CASE
WHEN order_count = 1 THEN 1
ELSE 0
END
) as one_order
FROM(
SELECT ID_Customer, count(DISTINCT ID_Order) as order_count
FROM orders
GROUP BY ID_Customer
) as t
;

-- checking same customer id with different cities or date : 0
SELECT count(o1.ID_Customer)
FROM orders as o1
JOIN orders as o2 ON o1.ID_Order = o2.ID_Order
WHERE (o1.city_name_fa != o2.city_name_fa) OR (o1.DateTime_CartFinalize != o2.DateTime_CartFinalize)
;

-- checking compatibality of all rows: 0 not compatible rows
SELECT count(*)
FROM orders
GROUP BY ID_Order
HAVING COUNT(DISTINCT ID_Customer) > 1 OR COUNT(DISTINCT DateTime_CartFinalize) > 1 OR COUNT(DISTINCT city_name_fa) > 1
;


