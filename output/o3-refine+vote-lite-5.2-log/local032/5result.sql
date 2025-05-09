WITH delivered AS (
    SELECT order_id,
           customer_id
    FROM olist_orders
    WHERE order_status = 'delivered'
),
-----------------------------------------------------------------
-- 1. DISTINCT CUSTOMER UNIQUE IDS PER SELLER
-----------------------------------------------------------------
seller_customer_counts AS (
    SELECT oi.seller_id,
           COUNT(DISTINCT c.customer_unique_id) AS distinct_customers
    FROM olist_order_items  oi
    JOIN delivered          d  ON d.order_id   = oi.order_id
    JOIN olist_customers    c  ON c.customer_id = d.customer_id
    GROUP BY oi.seller_id
),
best_customers AS (
    SELECT seller_id,
           distinct_customers
    FROM seller_customer_counts
    ORDER BY distinct_customers DESC, seller_id
    LIMIT 1
),
-----------------------------------------------------------------
-- 2. PROFIT PER SELLER  (price – freight_value)
-----------------------------------------------------------------
seller_profits AS (
    SELECT oi.seller_id,
           SUM(oi.price - oi.freight_value) AS profit
    FROM olist_order_items oi
    JOIN delivered         d ON d.order_id = oi.order_id
    GROUP BY oi.seller_id
),
best_profit AS (
    SELECT seller_id,
           profit
    FROM seller_profits
    ORDER BY profit DESC, seller_id
    LIMIT 1
),
-----------------------------------------------------------------
-- 3. DISTINCT ORDERS PER SELLER
-----------------------------------------------------------------
seller_orders AS (
    SELECT oi.seller_id,
           COUNT(DISTINCT oi.order_id) AS orders_ct
    FROM olist_order_items oi
    JOIN delivered         d ON d.order_id = oi.order_id
    GROUP BY oi.seller_id
),
best_orders AS (
    SELECT seller_id,
           orders_ct
    FROM seller_orders
    ORDER BY orders_ct DESC, seller_id
    LIMIT 1
),
-----------------------------------------------------------------
-- 4. 5‑STAR REVIEWS PER SELLER
-----------------------------------------------------------------
seller_reviews AS (
    SELECT oi.seller_id,
           COUNT(*) AS five_star_reviews
    FROM olist_order_items  oi
    JOIN delivered          d ON d.order_id     = oi.order_id
    JOIN olist_order_reviews r ON r.order_id    = oi.order_id
    WHERE r.review_score = 5
    GROUP BY oi.seller_id
),
best_reviews AS (
    SELECT seller_id,
           five_star_reviews
    FROM seller_reviews
    ORDER BY five_star_reviews DESC, seller_id
    LIMIT 1
)
-----------------------------------------------------------------
-- FINAL RESULT
-----------------------------------------------------------------
SELECT 'Most distinct customers' AS description,
       seller_id,
       distinct_customers       AS value
FROM best_customers

UNION ALL
SELECT 'Highest profit',
       seller_id,
       profit
FROM best_profit

UNION ALL
SELECT 'Most distinct orders',
       seller_id,
       orders_ct
FROM best_orders

UNION ALL
SELECT 'Most 5-star reviews',
       seller_id,
       five_star_reviews
FROM best_reviews;