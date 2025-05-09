WITH delivered_items AS (        /* every item that was really delivered */
    SELECT
        oi.order_id,
        oi.seller_id,
        oi.product_id,
        oi.price,
        o.order_approved_at,
        o.order_delivered_carrier_date
    FROM          order_items  oi
    JOIN          orders       o  ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),

/* review score per order (there can be several comments for the same order) */
order_review_score AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
),

/* enrich delivered items with the order‑level average review score */
seller_base AS (
    SELECT
        di.*,
        ors.avg_review_score
    FROM delivered_items di
    LEFT JOIN order_review_score ors
           ON ors.order_id = di.order_id
),

/* main performance figures for every seller */
seller_stats AS (
    SELECT
        sb.seller_id,
        s.seller_city,
        s.seller_state,
        COUNT(*)                                        AS total_units_sold,
        SUM(sb.price)                                   AS total_sales,
        AVG(sb.price)                                   AS avg_item_price,
        AVG(sb.avg_review_score)                        AS avg_review_score,
        AVG(julianday(sb.order_delivered_carrier_date)
            - julianday(sb.order_approved_at))          AS avg_packing_time_days
    FROM seller_base sb
    JOIN sellers   s ON s.seller_id = sb.seller_id
    GROUP BY sb.seller_id
    HAVING total_units_sold > 100            -- keep only sellers with >100 items sold
),

/* units sold per (seller, product category) */
seller_category_volume AS (
    SELECT
        sb.seller_id,
        pct.product_category_name_english               AS category_english,
        COUNT(*)                                        AS units_sold,
        ROW_NUMBER() OVER (PARTITION BY sb.seller_id
                           ORDER BY COUNT(*) DESC)      AS rn
    FROM seller_base sb
    JOIN products p ON p.product_id = sb.product_id
    LEFT JOIN product_category_name_translation pct
           ON pct.product_category_name = p.product_category_name
    GROUP BY sb.seller_id, category_english
),

/* best‑selling category for each seller */
top_category AS (
    SELECT seller_id, category_english
    FROM   seller_category_volume
    WHERE  rn = 1
)

SELECT
    ss.seller_id,
    ss.seller_city,
    ss.seller_state,
    ss.total_units_sold,
    ROUND(ss.total_sales,         4) AS total_sales,
    ROUND(ss.avg_item_price,      4) AS avg_item_price,
    ROUND(ss.avg_review_score,    4) AS avg_review_score,
    ROUND(ss.avg_packing_time_days,4) AS avg_packing_time_days,
    tc.category_english                 AS top_selling_category
FROM seller_stats ss
LEFT JOIN top_category tc ON tc.seller_id = ss.seller_id
ORDER BY ss.total_units_sold DESC,
         ss.seller_id;