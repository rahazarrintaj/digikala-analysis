-- Only working with orders table bcs there is no enough coverage with other tables

SELECT *
FROM orders;

-- checking for multiple_row rows : no multiple rows
SELECT count(*) as multiple_row
FROM orders
GROUP BY ID_Order, ID_Customer, ID_Item, DateTime_CartFinalize, Amount_Gross_Order, city_name_fa, Quantity_item
HAVING multiple_row > 1;

-- checking null values: NO NULL VALUES IN ANY COLUMNS
SELECT *
FROM orders
WHERE ID_Order IS NULL OR ID_Order = '' OR ID_Order = '\\N';

-- checking for negative or zero values in Amount_Gross_Order and Quantity_item :  3 rows with Amount_Gross_Order = 0 ---> keeping for quantity analysis but not for revenue
SELECT *
FROM orders
WHERE Amount_Gross_Order = 0 OR Amount_Gross_Order < 1 OR Quantity_item = 0 OR Quantity_item < 1;

-- looking at unique cities (to fix any typos)
SELECT DISTINCT city_name_fa
FROM orders
ORDER BY city_name_fa;
-- no issues

-- checking for possible arabic letters
SELECT city_name_fa
FROM orders
WHERE city_name_fa like '%ك%' ;

SELECT city_name_fa
FROM orders
WHERE city_name_fa like '%ي%' ;
-- no arabic letters

-- ckecking فاصله و نیم فاصبه
SELECT 	COUNT(DISTINCT city_name_fa), COUNT(DISTINCT TRIM(REPLACE(city_name_fa, '', ' ')))
FROM orders
;

-- No issues with dates
SELECT *
FROM orders
WHERE DateTime_CartFinalize LIKE '%-00-%' OR DateTime_CartFinalize LIKE '%0000-%' OR DateTime_CartFinalize LIKE '%-00%'
;

-- calculating sale amount per order
SELECT sum(Amount_Gross_Order * Quantity_item)  as sale_amount_per_order
FROM orders
GROUP BY ID_Order;


