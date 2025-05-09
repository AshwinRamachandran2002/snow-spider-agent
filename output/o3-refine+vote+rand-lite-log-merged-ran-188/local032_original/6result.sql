WITH delivered_orders AS (      -- all delivered orders
    SELECT order_id,
           customer_id
    FROM   olist_orders
    WHERE  order_status = 'delivered'
),

order_items_delivered AS (      -- items that belong to delivered orders
    SELECT oi.*,
           do.customer_id
    FROM   olist_order_items  oi
    JOIN   delivered_orders   do  USING (order_id)
),

/* ---------- 1. most distinct customer unique IDs ---------- */
seller_customer_counts AS (
    SELECT  oid.seller_id,
            COUNT(DISTINCT c.customer_unique_id) AS cnt_cust_unique
    FROM    order_items_delivered  oid
    JOIN    olist_customers        c  ON c.customer_id = oid.customer_id
    GROUP BY oid.seller_id
),
top_seller_customers AS (
    SELECT seller_id,
           cnt_cust_unique AS value
    FROM   seller_customer_counts
    ORDER  BY cnt_cust_unique DESC, seller_id
    LIMIT  1
),

/* ---------- 2. highest profit (Σ price – freight) ---------- */
seller_profit AS (
    SELECT  seller_id,
            SUM(price - freight_value) AS profit
    FROM    order_items_delivered
    GROUP BY seller_id
),
top_seller_profit AS (
    SELECT seller_id,
           profit AS value
    FROM   seller_profit
    ORDER  BY profit DESC, seller_id
    LIMIT  1
),

/* ---------- 3. most distinct orders ---------- */
seller_orders AS (
    SELECT  seller_id,
            COUNT(DISTINCT order_id) AS cnt_orders
    FROM    order_items_delivered
    GROUP BY seller_id
),
top_seller_orders AS (
    SELECT seller_id,
           cnt_orders AS value
    FROM   seller_orders
    ORDER  BY cnt_orders DESC, seller_id
    LIMIT  1
),

/* ---------- 4. most 5‑star reviews ---------- */
orders_with_5stars AS (
    SELECT DISTINCT r.order_id
    FROM   olist_order_reviews  r
    JOIN   delivered_orders     d  ON d.order_id = r.order_id
    WHERE  r.review_score = 5
),
seller_5star_counts AS (
    SELECT  oi.seller_id,
            COUNT(DISTINCT oi.order_id) AS cnt_5star
    FROM    olist_order_items  oi
    JOIN    orders_with_5stars o5  ON o5.order_id = oi.order_id
    GROUP BY oi.seller_id
),
top_seller_5star AS (
    SELECT seller_id,
           cnt_5star AS value
    FROM   seller_5star_counts
    ORDER  BY cnt_5star DESC, seller_id
    LIMIT  1
)

/* ---------- assemble the four winners ---------- */
SELECT seller_id,
       value,
       'Most distinct customer unique IDs' AS achievement
FROM   top_seller_customers

UNION ALL
SELECT seller_id,
       value,
       'Highest profit (price - freight)'  AS achievement
FROM   top_seller_profit

UNION ALL
SELECT seller_id,
       value,
       'Most distinct orders'             AS achievement
FROM   top_seller_orders

UNION ALL
SELECT seller_id,
       value,
       'Most 5-star reviews'              AS achievement
FROM   top_seller_5star;