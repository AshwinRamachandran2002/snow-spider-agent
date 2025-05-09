WITH delivered_orders AS (                 -- only delivered purchases
    SELECT order_id,
           customer_id
    FROM   olist_orders
    WHERE  order_status = 'delivered'
),

order_items_delivered AS (                 -- items that belong to delivered orders
    SELECT oi.*,
           do.customer_id
    FROM   olist_order_items AS oi
    JOIN   delivered_orders AS do
           ON do.order_id = oi.order_id
),

customers_unique AS (                      -- map customer_id -> customer_unique_id
    SELECT customer_id,
           customer_unique_id
    FROM   olist_customers
),

seller_core_stats AS (                     -- basic metrics per seller
    SELECT
        oi.seller_id,
        COUNT (DISTINCT cu.customer_unique_id)              AS distinct_customers,
        COUNT (DISTINCT oi.order_id)                        AS distinct_orders,
        SUM   (oi.price - oi.freight_value)                 AS profit
    FROM   order_items_delivered AS oi
    JOIN   customers_unique   AS cu
           ON cu.customer_id = oi.customer_id
    GROUP  BY oi.seller_id
),

five_star_stats AS (                       -- number of 5‑star reviews per seller
    SELECT
        oi.seller_id,
        COUNT (DISTINCT r.order_id)         AS five_star_count
    FROM   order_items_delivered AS oi
    JOIN   olist_order_reviews  AS r
           ON r.order_id = oi.order_id
    WHERE  r.review_score = 5
    GROUP  BY oi.seller_id
),

all_stats AS (                             -- merge the two stats tables
    SELECT
        sc.seller_id,
        sc.distinct_customers,
        sc.distinct_orders,
        sc.profit,
        COALESCE(fs.five_star_count,0) AS five_star_count
    FROM   seller_core_stats AS sc
    LEFT   JOIN five_star_stats AS fs
           ON fs.seller_id = sc.seller_id
),

max_values AS (                            -- seller(s) that top each metric
    SELECT
        (SELECT seller_id        FROM all_stats ORDER BY distinct_customers DESC, seller_id LIMIT 1) AS top_cust_seller,
        (SELECT distinct_customers FROM all_stats ORDER BY distinct_customers DESC, seller_id LIMIT 1) AS top_cust_val,

        (SELECT seller_id        FROM all_stats ORDER BY profit DESC, seller_id LIMIT 1)              AS top_profit_seller,
        (SELECT profit           FROM all_stats ORDER BY profit DESC, seller_id LIMIT 1)              AS top_profit_val,

        (SELECT seller_id        FROM all_stats ORDER BY distinct_orders DESC, seller_id LIMIT 1)     AS top_order_seller,
        (SELECT distinct_orders  FROM all_stats ORDER BY distinct_orders DESC, seller_id LIMIT 1)     AS top_order_val,

        (SELECT seller_id        FROM all_stats ORDER BY five_star_count DESC, seller_id LIMIT 1)     AS top_star_seller,
        (SELECT five_star_count  FROM all_stats ORDER BY five_star_count DESC, seller_id LIMIT 1)     AS top_star_val
)

-- final presentation: one row per achievement
SELECT 'Highest number of distinct customer unique IDs' AS achievement,
       top_cust_seller  AS seller_id,
       top_cust_val     AS value
FROM   max_values

UNION ALL
SELECT 'Highest profit (price - freight_value)',
       top_profit_seller,
       top_profit_val
FROM   max_values

UNION ALL
SELECT 'Highest number of distinct orders',
       top_order_seller,
       top_order_val
FROM   max_values

UNION ALL
SELECT 'Most 5-star ratings',
       top_star_seller,
       top_star_val
FROM   max_values;