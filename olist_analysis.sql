-- ================================================
-- OLIST E-COMMERCE SQL FORENSIC ANALYSIS
-- Author: Sanjana Ravi Kumar
-- Dataset: Olist Brazilian E-Commerce (Kaggle)
-- Tool: MySQL 9.3
-- Description: End-to-end forensic analysis of 100,000+
--              real orders across 5 business chapters:
--              Revenue Leakage, Customer LTV, Seller 
--              Benchmarking, Payment Risk, KPI Dashboard
-- ================================================
DROP DATABASE IF EXISTS olist_analysis;
CREATE DATABASE olist_analysis;
USE olist_analysis;
CREATE TABLE customers ( customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5) );
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
    );
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

CREATE TABLE payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

CREATE TABLE reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(100),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DECIMAL(18,15),
    geolocation_lng DECIMAL(18,15),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);
-- ================================================
-- NOTE: Update the file paths below to match your 
-- local machine before running these imports.
-- Example: 'C:/YourFolder/YourUploadsFolder/filename.csv'
-- ================================================
-- Customers
LOAD DATA INFILE 'C:/Users/sanja/OneDrive/Desktop/SANJ/SQL/Uploads/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- Orders
SET SESSION sql_mode = '';
LOAD DATA INFILE 'C:/Users/sanja/OneDrive/Desktop/SANJ/SQL/Uploads/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, 
 order_purchase_timestamp, order_approved_at,
 order_delivered_carrier_date, 
 order_delivered_customer_date,
 order_estimated_delivery_date);
-- Order items
LOAD DATA INFILE 'C:/Users/sanja/OneDrive/Desktop/SANJ/SQL/Uploads/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Products
LOAD DATA INFILE 'C:/Users/sanja/OneDrive/Desktop/SANJ/SQL/Uploads/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Sellers
LOAD DATA INFILE 'C:/Users/sanja/OneDrive/Desktop/SANJ/SQL/Uploads/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Payments
LOAD DATA INFILE 'C:/Users/sanja/OneDrive/Desktop/SANJ/SQL/Uploads/olist_order_payments_dataset.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Geolocation
LOAD DATA INFILE 'C:/Users/sanja/OneDrive/Desktop/SANJ/SQL/Uploads/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
-- Reviews
SET SESSION sql_mode = '';
LOAD DATA INFILE 'C:/Users/sanja/OneDrive/Desktop/SANJ/SQL/Uploads/olist_order_reviews_dataset.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
SELECT 
    (SELECT COUNT(*) FROM customers)   AS customers,
    (SELECT COUNT(*) FROM orders)      AS orders,
    (SELECT COUNT(*) FROM order_items) AS order_items,
    (SELECT COUNT(*) FROM products)    AS products,
    (SELECT COUNT(*) FROM sellers)     AS sellers,
    (SELECT COUNT(*) FROM payments)    AS payments,
    (SELECT COUNT(*) FROM reviews)     AS reviews,
    (SELECT COUNT(*) FROM geolocation) AS geolocation;
--  Order status breakdown
-- Business question: Where are orders falling through the cracks?

SELECT 
    order_status,
    COUNT(*)                                    AS total_orders,
    ROUND(COUNT(*) * 100.0 / 
        (SELECT COUNT(*) FROM orders), 2)       AS percentage_of_all_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;
-- Revenue leakage by order status
-- Business question: How much money is being lost to each problem status?

SELECT 
    o.order_status,
    COUNT(DISTINCT o.order_id)            AS total_orders,
    ROUND(SUM(oi.price), 2)              AS total_product_revenue,
    ROUND(SUM(oi.freight_value), 2)      AS total_freight_charged,
    ROUND(SUM(oi.price + 
              oi.freight_value), 2)      AS total_revenue_at_risk,
    ROUND(AVG(oi.price), 2)             AS avg_order_value
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY o.order_status
ORDER BY total_revenue_at_risk DESC;
-- Seller cancellation analysis
-- Business question: Which sellers are causing the most revenue loss?

SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT o.order_id)                     AS total_orders,
    SUM(CASE WHEN o.order_status = 'canceled' 
             THEN 1 ELSE 0 END)                    AS cancelled_orders,
    ROUND(SUM(CASE WHEN o.order_status = 'canceled' 
             THEN 1 ELSE 0 END) * 100.0 / 
             COUNT(DISTINCT o.order_id), 2)        AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN o.order_status = 'canceled' 
             THEN oi.price ELSE 0 END), 2)         AS revenue_lost_to_cancellations
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o       ON oi.order_id = o.order_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING cancelled_orders > 0
ORDER BY cancellation_rate_pct DESC
LIMIT 20;
-- Freight vs product value — margin killer analysis
-- Business question: Where is shipping eating into or exceeding product revenue?
SELECT 
    oi.order_id,
    ROUND(oi.price, 2)                              AS product_price,
    ROUND(oi.freight_value, 2)                      AS freight_cost,
    ROUND(oi.freight_value / oi.price * 100, 2)    AS freight_as_pct_of_price,
    CASE 
        WHEN oi.freight_value >= oi.price 
             THEN 'critical — freight exceeds product'
        WHEN oi.freight_value >= oi.price * 0.75 
             THEN 'high risk — freight over 75% of price'
        WHEN oi.freight_value >= oi.price * 0.50 
             THEN 'moderate — freight over 50% of price'
        ELSE 'acceptable'
    END                                             AS margin_risk_category,
    p.product_category_name,
    s.seller_state
FROM order_items oi
JOIN products p  ON oi.product_id = p.product_id
JOIN sellers s   ON oi.seller_id  = s.seller_id
WHERE oi.price > 0
ORDER BY freight_as_pct_of_price DESC
LIMIT 20;
-- Margin risk summary by product category
-- Business question: Which categories have a structural freight problem?

SELECT 
    p.product_category_name,
    COUNT(*)                                            AS total_items,
    ROUND(AVG(oi.price), 2)                            AS avg_product_price,
    ROUND(AVG(oi.freight_value), 2)                    AS avg_freight_cost,
    ROUND(AVG(oi.freight_value / oi.price * 100), 2)  AS avg_freight_pct,
    SUM(CASE 
        WHEN oi.freight_value >= oi.price 
        THEN 1 ELSE 0 END)                             AS critical_items,
    ROUND(SUM(CASE 
        WHEN oi.freight_value >= oi.price 
        THEN oi.freight_value - oi.price 
        ELSE 0 END), 2)                                AS total_money_lost
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE oi.price > 0
GROUP BY p.product_category_name
HAVING critical_items > 0
ORDER BY total_money_lost DESC
LIMIT 15;
-- Late delivery analysis
-- Business question: How bad is Olist's delivery performance 
-- and which sellers are responsible?

SELECT
    o.order_id,
    o.order_status,
    DATE(o.order_purchase_timestamp)        AS purchase_date,
    DATE(o.order_estimated_delivery_date)   AS promised_delivery,
    DATE(o.order_delivered_customer_date)   AS actual_delivery,
    DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date)    AS days_late,
    CASE
        WHEN o.order_delivered_customer_date 
             <= o.order_estimated_delivery_date 
             THEN 'on time'
        WHEN DATEDIFF(
             o.order_delivered_customer_date,
             o.order_estimated_delivery_date) <= 7
             THEN 'slightly late (1-7 days)'
        WHEN DATEDIFF(
             o.order_delivered_customer_date,
             o.order_estimated_delivery_date) <= 30
             THEN 'very late (8-30 days)'
        ELSE 'critically late (30+ days)'
    END                                     AS delivery_status,
    r.review_score
FROM orders o
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
ORDER BY days_late DESC
LIMIT 20;
-- Delivery performance scorecard
-- Business question: What percentage of orders fall into each 
-- delivery category, and how does lateness affect review scores?

SELECT
    CASE
        WHEN o.order_delivered_customer_date 
             <= o.order_estimated_delivery_date
             THEN '1 — on time'
        WHEN DATEDIFF(
             o.order_delivered_customer_date,
             o.order_estimated_delivery_date) <= 7
             THEN '2 — slightly late (1-7 days)'
        WHEN DATEDIFF(
             o.order_delivered_customer_date,
             o.order_estimated_delivery_date) <= 30
             THEN '3 — very late (8-30 days)'
        ELSE '4 — critically late (30+ days)'
    END                                          AS delivery_tier,
    COUNT(*)                                     AS total_orders,
    ROUND(COUNT(*) * 100.0 / 
        (SELECT COUNT(*) FROM orders 
         WHERE order_status = 'delivered'
         AND order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
        ), 2)                                    AS pct_of_delivered,
    ROUND(AVG(r.review_score), 2)               AS avg_review_score,
    ROUND(AVG(DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date)), 1)    AS avg_days_late
FROM orders o
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_tier
ORDER BY delivery_tier;
-- RFM base calculation (compatible version)
SELECT
    customer_unique_id,
    frequency,
    monetary,
    recency_days,
    CASE 
        WHEN recency_days <= 90  THEN 4
        WHEN recency_days <= 180 THEN 3
        WHEN recency_days <= 270 THEN 2
        ELSE 1
    END AS recency_score,
    CASE
        WHEN frequency >= 3 THEN 4
        WHEN frequency = 2  THEN 3
        WHEN frequency = 1  THEN 2
        ELSE 1
    END AS frequency_score,
    CASE
        WHEN monetary >= 500  THEN 4
        WHEN monetary >= 200  THEN 3
        WHEN monetary >= 100  THEN 2
        ELSE 1
    END AS monetary_score
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)           AS frequency,
        ROUND(SUM(oi.price), 2)             AS monetary,
        DATEDIFF(
            '2018-10-01',
            MAX(o.order_purchase_timestamp)) AS recency_days
    FROM customers c
    JOIN orders o       ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.order_status NOT IN ('canceled','unavailable')
    GROUP BY c.customer_unique_id
) AS rfm_base
ORDER BY monetary DESC
LIMIT 20;
-- Customer segmentation
-- Business question: How many customers fall into each segment?

SELECT
    customer_unique_id,
    frequency,
    monetary,
    recency_days,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score AS rfm_total,
    CASE
        WHEN recency_score + frequency_score + monetary_score >= 10
             THEN 'Champion'
        WHEN recency_score + frequency_score + monetary_score >= 8
             THEN 'Loyal customer'
        WHEN recency_score >= 3 
             AND frequency_score <= 2
             THEN 'Promising — new customer'
        WHEN recency_score <= 2 
             AND frequency_score >= 3
             THEN 'At risk — was loyal'
        WHEN recency_score = 1 
             AND monetary_score >= 3
             THEN 'Cannot lose — high value gone cold'
        ELSE 'Lost or low value'
    END AS customer_segment
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)           AS frequency,
        ROUND(SUM(oi.price), 2)             AS monetary,
        DATEDIFF(
            '2018-10-01',
            MAX(o.order_purchase_timestamp)) AS recency_days,
        CASE 
            WHEN DATEDIFF('2018-10-01',
                 MAX(o.order_purchase_timestamp)) <= 90  
                 THEN 4
            WHEN DATEDIFF('2018-10-01',
                 MAX(o.order_purchase_timestamp)) <= 180 
                 THEN 3
            WHEN DATEDIFF('2018-10-01',
                 MAX(o.order_purchase_timestamp)) <= 270 
                 THEN 2
            ELSE 1
        END AS recency_score,
        CASE
            WHEN COUNT(DISTINCT o.order_id) >= 3 THEN 4
            WHEN COUNT(DISTINCT o.order_id) = 2  THEN 3
            WHEN COUNT(DISTINCT o.order_id) = 1  THEN 2
            ELSE 1
        END AS frequency_score,
        CASE
            WHEN ROUND(SUM(oi.price),2) >= 500 THEN 4
            WHEN ROUND(SUM(oi.price),2) >= 200 THEN 3
            WHEN ROUND(SUM(oi.price),2) >= 100 THEN 2
            ELSE 1
        END AS monetary_score
    FROM customers c
    JOIN orders o       ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.order_status NOT IN ('canceled','unavailable')
    GROUP BY c.customer_unique_id
) AS rfm_base
ORDER BY rfm_total DESC
LIMIT 20;
-- Customer segment summary (clean version)

SELECT
    customer_segment,
    COUNT(*)                             AS total_customers,
    ROUND(AVG(monetary), 2)             AS avg_spend,
    ROUND(AVG(recency_days), 0)         AS avg_days_since_purchase,
    ROUND(AVG(frequency), 2)            AS avg_orders
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)       AS frequency,
        ROUND(SUM(oi.price), 2)         AS monetary,
        DATEDIFF('2018-10-01',
            MAX(o.order_purchase_timestamp)) AS recency_days,
        CASE
            WHEN (CASE WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) <= 90 THEN 4
                       WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) <= 180 THEN 3
                       WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) <= 270 THEN 2
                       ELSE 1 END)
                +
                (CASE WHEN COUNT(DISTINCT o.order_id) >= 3 THEN 4
                      WHEN COUNT(DISTINCT o.order_id) = 2  THEN 3
                      WHEN COUNT(DISTINCT o.order_id) = 1  THEN 2
                      ELSE 1 END)
                +
                (CASE WHEN ROUND(SUM(oi.price),2) >= 500 THEN 4
                      WHEN ROUND(SUM(oi.price),2) >= 200 THEN 3
                      WHEN ROUND(SUM(oi.price),2) >= 100 THEN 2
                      ELSE 1 END) >= 10 THEN 'Champion'
            WHEN (CASE WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) <= 90 THEN 4
                       WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) <= 180 THEN 3
                       WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) <= 270 THEN 2
                       ELSE 1 END)
                +
                (CASE WHEN COUNT(DISTINCT o.order_id) >= 3 THEN 4
                      WHEN COUNT(DISTINCT o.order_id) = 2  THEN 3
                      WHEN COUNT(DISTINCT o.order_id) = 1  THEN 2
                      ELSE 1 END)
                +
                (CASE WHEN ROUND(SUM(oi.price),2) >= 500 THEN 4
                      WHEN ROUND(SUM(oi.price),2) >= 200 THEN 3
                      WHEN ROUND(SUM(oi.price),2) >= 100 THEN 2
                      ELSE 1 END) >= 8 THEN 'Loyal customer'
            WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) <= 180
                 AND COUNT(DISTINCT o.order_id) = 1
                 THEN 'Promising — new customer'
            WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) > 270
                 AND COUNT(DISTINCT o.order_id) >= 3
                 THEN 'At risk — was loyal'
            WHEN DATEDIFF('2018-10-01', MAX(o.order_purchase_timestamp)) > 270
                 AND ROUND(SUM(oi.price),2) >= 500
                 THEN 'Cannot lose — high value gone cold'
            ELSE 'Lost or low value'
        END AS customer_segment
    FROM customers c
    JOIN orders o       ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.order_status NOT IN ('canceled','unavailable')
    GROUP BY c.customer_unique_id
) AS rfm_base
GROUP BY customer_segment
ORDER BY total_customers DESC;
-- Cohort retention analysis (compatible version)

SELECT
    cohort_month,
    COUNT(DISTINCT customer_unique_id)          AS cohort_size,
    SUM(CASE WHEN total_orders >= 1 
             THEN 1 ELSE 0 END)                AS active_customers,
    SUM(CASE WHEN total_orders >= 2 
             THEN 1 ELSE 0 END)                AS returned_for_2nd_order,
    SUM(CASE WHEN total_orders >= 3 
             THEN 1 ELSE 0 END)                AS returned_for_3rd_order,
    SUM(CASE WHEN total_orders >= 4 
             THEN 1 ELSE 0 END)                AS returned_4th_plus,
    ROUND(SUM(CASE WHEN total_orders >= 2 
             THEN 1 ELSE 0 END) * 100.0 / 
             COUNT(DISTINCT customer_unique_id), 2) AS retention_rate_pct
FROM (
    SELECT
        c.customer_unique_id,
        DATE_FORMAT(
            MIN(o.order_purchase_timestamp), 
            '%Y-%m')                            AS cohort_month,
        COUNT(DISTINCT o.order_id)              AS total_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled','unavailable')
    GROUP BY c.customer_unique_id
) AS customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month;
-- ================================================
-- Retention rate verification
-- The cohort query above shows retention per month.
-- This query gives the overall platform retention rate.
-- Result: 6.44% of customers ever made a second purchase.
-- ================================================
SELECT
    COUNT(DISTINCT c.customer_unique_id)        AS total_unique_customers,
    SUM(CASE WHEN order_count >= 2 
             THEN 1 ELSE 0 END)                 AS repeat_customers,
    ROUND(SUM(CASE WHEN order_count >= 2 
             THEN 1 ELSE 0 END) * 100.0 / 
             COUNT(DISTINCT c.customer_unique_id), 2) AS retention_rate_pct
FROM customers c
JOIN (
    SELECT 
        customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c2
    JOIN orders o ON c2.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled','unavailable')
    GROUP BY customer_unique_id
) AS order_counts 
ON c.customer_unique_id = order_counts.customer_unique_id;

-- Seller performance benchmarking within category
-- Business question: Who are the best and worst sellers 
-- relative to their own category peers?

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    p.product_category_name,
    COUNT(DISTINCT o.order_id)                      AS total_orders,
    ROUND(SUM(oi.price), 2)                        AS total_revenue,
    ROUND(AVG(oi.price), 2)                        AS avg_order_value,
    ROUND(AVG(r.review_score), 2)                  AS avg_review_score,
    SUM(CASE WHEN o.order_status = 'canceled' 
             THEN 1 ELSE 0 END)                    AS cancellations,
    ROUND(SUM(CASE WHEN o.order_status = 'canceled' 
             THEN 1 ELSE 0 END) * 100.0 / 
             COUNT(DISTINCT o.order_id), 2)        AS cancellation_rate
FROM sellers s
JOIN order_items oi ON s.seller_id   = oi.seller_id
JOIN orders o       ON oi.order_id   = o.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN reviews r ON o.order_id    = r.order_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state,
    p.product_category_name
HAVING total_orders >= 10
ORDER BY p.product_category_name, total_revenue DESC
LIMIT 30;
-- Seller classification

SELECT
    t.seller_id,
    s.seller_city,
    t.total_revenue,
    t.avg_review_score,
    t.cancellation_rate,
    CASE
        WHEN t.total_revenue > 100000
             AND t.avg_review_score >= 4.0
             THEN 'Top performer — elite seller'
        WHEN t.total_revenue > 100000
             AND t.avg_review_score < 3.7
             THEN 'Revenue strong but quality risk'
        WHEN t.total_revenue BETWEEN 50000 AND 100000
             AND t.avg_review_score >= 4.0
             THEN 'Hidden gem — strong revenue and quality'
        WHEN t.total_revenue BETWEEN 10000 AND 50000
             AND t.avg_review_score >= 4.2
             THEN 'Quality strong but undermonetised'
        WHEN t.cancellation_rate > 5
             THEN 'High cancellation — needs review'
        ELSE 'Average performer'
    END AS seller_classification
FROM (
    SELECT
        s.seller_id,
        ROUND(SUM(oi.price), 2)                AS total_revenue,
        ROUND(AVG(r.review_score), 2)          AS avg_review_score,
        ROUND(SUM(CASE
            WHEN o.order_status = 'canceled'
            THEN 1 ELSE 0 END) * 100.0 /
            COUNT(DISTINCT o.order_id), 2)     AS cancellation_rate
    FROM sellers s
    JOIN order_items oi ON s.seller_id = oi.seller_id
    JOIN orders o       ON oi.order_id = o.order_id
    LEFT JOIN reviews r ON o.order_id  = r.order_id
    GROUP BY s.seller_id
    HAVING COUNT(DISTINCT o.order_id) >= 10
) AS t
JOIN sellers s ON t.seller_id = s.seller_id
ORDER BY t.total_revenue DESC
LIMIT 40;
-- Seller classification summary
-- Business question: How many sellers fall into each performance category?

SELECT
    seller_classification,
    COUNT(*)                                    AS total_sellers,
    ROUND(COUNT(*) * 100.0 / 
        (SELECT COUNT(DISTINCT seller_id) 
         FROM sellers), 2)                      AS pct_of_all_sellers,
    ROUND(AVG(total_revenue), 2)               AS avg_revenue,
    ROUND(AVG(avg_review_score), 2)            AS avg_review_score,
    ROUND(AVG(cancellation_rate), 2)           AS avg_cancellation_rate
FROM (
    SELECT
        t.seller_id,
        t.total_revenue,
        t.avg_review_score,
        t.cancellation_rate,
        CASE
            WHEN t.total_revenue > 100000
                 AND t.avg_review_score >= 4.0
                 THEN 'Top performer — elite seller'
            WHEN t.total_revenue > 100000
                 AND t.avg_review_score < 3.7
                 THEN 'Revenue strong but quality risk'
            WHEN t.total_revenue BETWEEN 50000 AND 100000
                 AND t.avg_review_score >= 4.0
                 THEN 'Hidden gem — strong revenue and quality'
            WHEN t.total_revenue BETWEEN 10000 AND 50000
                 AND t.avg_review_score >= 4.2
                 THEN 'Quality strong but undermonetised'
            WHEN t.cancellation_rate > 5
                 THEN 'High cancellation — needs review'
            ELSE 'Average performer'
        END AS seller_classification
    FROM (
        SELECT
            s.seller_id,
            ROUND(SUM(oi.price), 2)                AS total_revenue,
            ROUND(AVG(r.review_score), 2)          AS avg_review_score,
            ROUND(SUM(CASE
                WHEN o.order_status = 'canceled'
                THEN 1 ELSE 0 END) * 100.0 /
                COUNT(DISTINCT o.order_id), 2)     AS cancellation_rate
        FROM sellers s
        JOIN order_items oi ON s.seller_id = oi.seller_id
        JOIN orders o       ON oi.order_id = o.order_id
        LEFT JOIN reviews r ON o.order_id  = r.order_id
        GROUP BY s.seller_id
        HAVING COUNT(DISTINCT o.order_id) >= 10
    ) AS t
) AS classified
GROUP BY seller_classification
ORDER BY total_sellers DESC;
-- Payment type analysis
-- Business question: How do customers pay, and does payment
-- method correlate with order value?

SELECT
    p.payment_type,
    COUNT(DISTINCT p.order_id)              AS total_orders,
    ROUND(SUM(p.payment_value), 2)         AS total_payment_value,
    ROUND(AVG(p.payment_value), 2)         AS avg_payment_value,
    ROUND(AVG(p.payment_installments), 2)  AS avg_installments,
    ROUND(COUNT(DISTINCT p.order_id) * 100.0 /
        (SELECT COUNT(DISTINCT order_id)
         FROM payments), 2)                AS pct_of_orders
FROM payments p
GROUP BY p.payment_type
ORDER BY total_orders DESC;
-- Instalment count vs review score
-- Business question: Do customers who pay in more instalments
-- have worse satisfaction? (proxy for financial stress)

SELECT
    p.payment_installments,
    COUNT(DISTINCT p.order_id)             AS total_orders,
    ROUND(AVG(r.review_score), 2)         AS avg_review_score,
    ROUND(AVG(p.payment_value), 2)        AS avg_order_value,
    ROUND(SUM(p.payment_value), 2)        AS total_revenue
FROM payments p
LEFT JOIN reviews r ON p.order_id = r.order_id
WHERE p.payment_type = 'credit_card'
  AND p.payment_installments > 0
GROUP BY p.payment_installments
ORDER BY p.payment_installments ASC;
-- Credit risk proxy scoring
-- Business question: Which orders show signs of financial stress
-- based on payment behaviour?
SELECT
    payment_risk_tier,
    COUNT(*)                                    AS total_orders,
    ROUND(AVG(payment_value), 2)               AS avg_order_value,
    ROUND(AVG(payment_installments), 2)        AS avg_installments,
    ROUND(AVG(review_score), 2)                AS avg_review_score,
    ROUND(SUM(payment_value), 2)               AS total_exposure
FROM (
    SELECT
        p.order_id,
        p.payment_value,
        p.payment_installments,
        r.review_score,
        CASE
            WHEN p.payment_installments >= 10
                 AND p.payment_value >= 300
                 THEN 'High risk — large purchase, many instalments'
            WHEN p.payment_installments >= 6
                 AND p.payment_value >= 200
                 THEN 'Medium risk — mid purchase, extended payment'
            WHEN p.payment_installments >= 3
                 AND p.payment_value >= 100
                 THEN 'Low risk — moderate instalment behaviour'
            WHEN p.payment_installments = 1
                 THEN 'No risk — paid in full'
            ELSE 'Minimal risk — short instalment, low value'
        END AS payment_risk_tier
    FROM payments p
    LEFT JOIN reviews r ON p.order_id = r.order_id
    WHERE p.payment_type = 'credit_card'
      AND p.payment_installments > 0
) AS risk_scored
GROUP BY payment_risk_tier
ORDER BY total_exposure DESC;
-- ================================================
-- MASTER KPI DASHBOARD
-- Olist E-Commerce Forensic Analysis
-- All key findings in one query
-- ================================================
SELECT 'REVENUE' AS category, 'Total Gross Revenue' AS kpi, '$13,591,643' AS value
UNION ALL SELECT 'REVENUE', 'Avg Order Value', '$120.65'
UNION ALL SELECT 'REVENUE', 'Revenue Lost to Cancellations', '$95,235'
UNION ALL SELECT 'REVENUE', 'Revenue Stuck in Pipeline', '$121,965'
UNION ALL SELECT 'REVENUE', 'Freight Margin Losses (Top 5 Categories)', '$13,221'
UNION ALL SELECT '---', '---', '---'
UNION ALL SELECT 'DELIVERY', 'Total Orders', '98,666'
UNION ALL SELECT 'DELIVERY', 'On Time Delivery Rate', '91.89%'
UNION ALL SELECT 'DELIVERY', 'Worst Single Delivery Delay', '188 days'
UNION ALL SELECT 'DELIVERY', 'On Time Avg Review Score', '4.29 / 5'
UNION ALL SELECT 'DELIVERY', 'Critically Late Avg Review Score', '2.05 / 5'
UNION ALL SELECT '---', '---', '---'
UNION ALL SELECT 'CUSTOMERS', 'Total Unique Customers', '94,990'
UNION ALL SELECT 'CUSTOMERS', 'Repeat Customers', '6,118'
UNION ALL SELECT 'CUSTOMERS', 'Retention Rate', '6.44%'
UNION ALL SELECT 'CUSTOMERS', 'Champion Customers', '760'
UNION ALL SELECT 'CUSTOMERS', 'High Value Gone Cold', '1,572'
UNION ALL SELECT 'CUSTOMERS', 'Dormant Revenue Opportunity', '$1.48M'
UNION ALL SELECT '---', '---', '---'
UNION ALL SELECT 'SELLERS', 'Total Active Sellers', '3,095'
UNION ALL SELECT 'SELLERS', 'Platform Avg Review Score', '4.03 / 5'
UNION ALL SELECT 'SELLERS', 'Elite Top Performers', '12 sellers'
UNION ALL SELECT 'SELLERS', 'High Cancellation Sellers', '49 sellers'
UNION ALL SELECT 'SELLERS', 'Undermonetised Quality Sellers', '89 sellers'
UNION ALL SELECT '---', '---', '---'
UNION ALL SELECT 'PAYMENTS', 'Credit Card Share', '76.94%'
UNION ALL SELECT 'PAYMENTS', 'Avg Credit Instalments', '3.51 months'
UNION ALL SELECT 'PAYMENTS', 'High Risk Instalment Exposure', '$2,333,772'
UNION ALL SELECT 'PAYMENTS', 'No Risk (Paid in Full) Orders', '25,549';
-- ================================================
-- BUSINESS RECOMMENDATIONS SUMMARY
-- The "so what" of everything we found
-- ================================================
SELECT '1' AS priority,
       'Revenue Recovery' AS recommendation_area,
       'Cancel high-freight low-value listings' AS action,
       'Electronics and construction tools show 2000%+ freight ratios' AS evidence,
       '$13,221 direct losses recoverable' AS estimated_impact

UNION ALL

SELECT '2',
       'Pipeline Fix',
       'Investigate 613 paid but unshipped orders immediately',
       'Invoiced + processing orders sitting idle with customer money held',
       '$121,965 stuck in pipeline'

UNION ALL

SELECT '3',
       'Seller Management',
       'Place 49 high-cancellation sellers on performance review',
       '11.52% avg cancellation rate vs 0.23% platform average',
       'Reduces $95,235 annual cancellation losses'

UNION ALL

SELECT '4',
       'Customer Retention',
       'Launch win-back campaign for 1,572 high-value cold customers',
       'Avg spend $943 each, not purchased in 418 days',
       '$1.48M potential repeat revenue'

UNION ALL

SELECT '5',
       'Delivery Operations',
       'Investigate 2017 logistics failure affecting hundreds of orders',
       'Multiple orders 150-188 days late all sharing same delivery date',
       'Review score drops from 4.29 to 2.05 when orders are late'

UNION ALL

SELECT '6',
       'Credit Risk',
       'Set maximum instalment limits per product category',
       '2,291 high-risk orders with $2.33M exposure, lowest satisfaction 3.89',
       'Reduces refund risk on high-instalment purchases'

UNION ALL

SELECT '7',
       'Seller Development',
       'Create growth programme for 89 undermonetised quality sellers',
       'Avg review 4.37 but revenue only $19,919 vs $152,374 for top performers',
       '3x revenue potential without quality risk'

UNION ALL

SELECT '8',
       'Platform Health',
       'Protect top 12 elite sellers with dedicated account management',
       'Top 12 sellers avg $152,374 revenue each, carry disproportionate platform share',
       'Losing 3 elite sellers = $457,000 revenue risk';