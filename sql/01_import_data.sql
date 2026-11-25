
CREATE DATABASE IF NOT EXISTS digikala_kaggle
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE digikala_kaggle;

SET GLOBAL local_infile = 1;

-- 1. PRICE
CREATE TABLE price (
    id BIGINT,
    product_variant_id BIGINT,
    selling_price BIGINT,
    rrp_price BIGINT,
    base_price DOUBLE,
    buy_price DOUBLE,
    order_limit BIGINT,
    start_at VARCHAR(100),
    end_at VARCHAR(100),
    tags TEXT,
    show_in_price_history INT,
    active INT,
    created_at VARCHAR(100),
    product_id BIGINT,
    marketplace_seller_id BIGINT
);


-- 2. ORDERS
CREATE TABLE orders (
    ID_Order BIGINT,
    ID_Customer BIGINT,
    ID_Item BIGINT,
    DateTime_CartFinalize VARCHAR(100),
    Amount_Gross_Order DOUBLE,
    city_name_fa VARCHAR(255),
    Quantity_item DOUBLE
);


-- 3. PRODUCTS
CREATE TABLE products (
    id BIGINT,
    product_title_fa TEXT,
    product_title_en TEXT,
    url_code TEXT,
    title_alt TEXT,
    category_title_fa TEXT,
    category_keywords TEXT,
    brand_name_fa VARCHAR(500),
    brand_name_en VARCHAR(500),
    product_attributes LONGTEXT
);


-- 4. COMMENTS
CREATE TABLE comments (
    product_id BIGINT,
    product_title TEXT,
    title_en TEXT,
    user_id BIGINT,
    likes BIGINT,
    dislikes BIGINT,
    verification_status VARCHAR(255),
    recommend VARCHAR(255),
    title TEXT,
    comment LONGTEXT,
    advantages LONGTEXT,
    disadvantages LONGTEXT
);


-- 5. COMMENTS_CONFIRM
CREATE TABLE comments_confirm (
    product_id BIGINT,
    confirmed_at VARCHAR(100),
    comment LONGTEXT
);


LOAD DATA LOCAL INFILE
'D:/DATA ANALYSIS/PROJECT/digikala-analysis/data/price.csv'
INTO TABLE price
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE
'D:/DATA ANALYSIS/PROJECT/digikala-analysis/data/products.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE
'D:/DATA ANALYSIS/PROJECT/digikala-analysis/data/orders.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE
'D:/DATA ANALYSIS/PROJECT/digikala-analysis/data/comments.csv'
INTO TABLE comments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE
'D:/DATA ANALYSIS/PROJECT/digikala-analysis/data/comments_confirm.csv'
INTO TABLE comments_confirm
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

DROP TABLE customers;





