-- --------------------------------------------------------------------ORDERS---------------------------------------------------------------------------------------------

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

-- Amount_Gross_Order is different in each instance
SELECT * 
FROM orders
WHERE ID_Order = '9916301';

-- alter DateTime_CartFinalize column to datetime
/*ALTER TABLE orders
MODIFY DateTime_CartFinalize DATETIME NOT NULL;*/


-- '2013-09-27 12:03:00' to '2018-12-11 04:47:23' ORDERS timeline (analyze from 2013-10  to 2018-11)
SELECT min(DateTime_CartFinalize) as min, max(DateTime_CartFinalize) as max
FROM orders
;

-- number of orders for each month (ascending through time)
SELECT year(DateTime_CartFinalize) as order_year, month(DateTime_CartFinalize) as order_month, count(DISTINCT ID_Order) as number_of_orders
FROM orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month
;
-- starting from 2013-9 : 6, 73, 90, 116, 140, 148  in the end: 2018-10 to 2018-12 : 5485, 5933, 2154 (we will consider all months bcs they grow gradually)

-- we have 906 cities
SELECT count(DISTINCT city_name_fa)
FROM orders
;


-- --------------------------------------------------------------------PRODUCTS---------------------------------------------------------------------------------------------

-- product_attributes are saved as json files, bcs every product has different attributes

SELECT * 
FROM products;

DESCRIBE products;

-- COUNT(*) = '100000', COUNT(DISTINCT id) = '100000'
SELECT COUNT(*), COUNT(DISTINCT id) 
FROM products;

-- --------------------------------------------------------------------PRICE---------------------------------------------------------------------------------------------

SELECT *  
FROM price;

DESCRIBE price;


-- base_price '13193', buy_price '13282', start_at '13235', end_at '13235' are '\N' (NULL)   ---> change '\N' to Null?
SELECT count(*) 
FROM price
WHERE end_at = '\\N';

-- only 153  selling_price != rrp_price and we have '13324' logged price so sales question cannot be answered
SELECT count(*) 
FROM price
WHERE NOT selling_price = rrp_price;

-- there are multiple rows with the same product_id and different product_variant_id
SELECT count(DISTINCT product_variant_id) as variant_per_product
FROM price
GROUP BY product_id
ORDER BY variant_per_product DESC;

-- alter created_at column to datetime
/*ALTER TABLE price
MODIFY created_at DATETIME NOT NULL;*/

-- '2018-11-19 17:21:57' to  '2018-11-26 19:00:16' PRICING timeline which shows this prices were submitted in a one week period so we cannot show pricing over time
SELECT min(created_at) as min, max(created_at) as max
FROM price
;

-- min and max price
-- prices are proabily in tomans from 9800t to 290000000t
SELECT min(selling_price) as min_price , max(selling_price) as max_price  
FROM price;

-- 290000000 'تلویزیون کیولد هوشمند خمیده سامسونگ مدل 65Q7880 سایز 65 اینچ' and 'دستمال میکروفایبر نانسی چند منظوره' is '9800' n year 2018 these prices seem to be in RIAL
SELECT pr.selling_price, p.product_title_fa 
FROM products as p
JOIN price as pr ON p.id = pr.product_id
WHERE pr.selling_price = '9800' OR  pr.selling_price = '290000000'
;


-- --------------------------------------------------------------------COMMENTS---------------------------------------------------------------------------------------------
-- advantages and disadvantages are json files
SELECT *
FROM comments;

DESCRIBE comments;

-- --------------------------------------------------------------------COMMENTS_CONFIRM---------------------------------------------------------------------------------------------
-- is the same as comments table with only a confirmed_at date (has 8 more rows) ---> not use this table?
SELECT * 
FROM comments_confirm;

DESCRIBE comments_confirm;

-- alter confirmed_at column to datetime
/*ALTER TABLE comments_confirm
MODIFY confirmed_at DATETIME NOT NULL;*/

-- '2018-03-20 09:24:03' to '2018-10-20 13:44:45' COMMENTS timeline
SELECT min(confirmed_at) as min, max(confirmed_at) as max
FROM comments_confirm
;


-- '100000'
SELECT count(*)  
FROM products;

-- '13324'
SELECT count(*)  
FROM price;

-- '200000'
SELECT count(*)  
FROM orders;

-- '100000'
SELECT count(*)  
FROM comments;

-- '100008'
SELECT count(*)  
FROM comments_confirm;

-- only '1621' producs from price table have comments ----> very low amount
SELECT
    COUNT(DISTINCT p.product_id) AS products_with_comments_and_price
FROM price AS p
JOIN comments AS c
    ON p.product_id = c.product_id;

-- only '5708' producs from products table have comments ----> very low amount
SELECT
    COUNT(DISTINCT p.id) AS products_with_comments
FROM products AS p
JOIN comments AS c
    ON p.id = c.product_id;

-- only ''506'' producs from products table have price ----> very low amount
SELECT
    COUNT(DISTINCT p.id) AS products_with_price
FROM products AS p
JOIN price AS pr
    ON p.id = pr.product_id;


-- '3.45' coverage_percentage
SELECT
    COUNT(*) AS total_order_rows,

    SUM(CASE
        WHEN p.id IS NOT NULL THEN 1
        ELSE 0
    END) AS matched_rows,

    SUM(CASE
        WHEN p.id IS NULL THEN 1
        ELSE 0
    END) AS unmatched_rows,

    ROUND(
        SUM(CASE WHEN p.id IS NOT NULL THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS coverage_percentage

FROM orders AS o
LEFT JOIN products AS p
    ON o.ID_Item = p.id;


-- '2.6' amount_coverage_percentage
SELECT

    SUM(o.Amount_Gross_Order) AS total_amount,

    SUM(CASE
        WHEN p.id IS NOT NULL
        THEN o.Amount_Gross_Order
        ELSE 0
    END) AS matched_amount,

    SUM(CASE
        WHEN p.id IS NULL
        THEN o.Amount_Gross_Order
        ELSE 0
    END) AS unmatched_amount,

    ROUND(
        SUM(CASE
            WHEN p.id IS NOT NULL
            THEN o.Amount_Gross_Order
            ELSE 0
        END) * 100.0 /
        NULLIF(SUM(o.Amount_Gross_Order), 0),
        2
    ) AS amount_coverage_percentage

FROM orders AS o
LEFT JOIN products AS p
    ON o.ID_Item = p.id;
