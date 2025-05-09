WITH seller_sales AS (          -- basic sales metrics per seller
    SELECT
        oi.seller_id,
        COUNT(*)                       AS items_sold,
        SUM(oi.price)                  AS total_sales,
        AVG(oi.price)                  AS avg_item_price
    FROM order_items AS oi
    GROUP BY oi.seller_id
),

seller_reviews AS (             -- average review score per seller
    SELECT
        oi.seller_id,
        AVG(orv.review_score)    AS avg_review_score
    FROM order_items           AS oi
    JOIN orders               AS o   ON o.order_id = oi.order_id
    JOIN order_reviews        AS orv ON orv.order_id = o.order_id
    GROUP BY oi.seller_id
),

seller_packing AS (             -- average packing time (approved → carrier) per seller
    SELECT
        oi.seller_id,
        AVG(
            julianday(o.order_delivered_carrier_date) -
            julianday(o.order_approved_at)
        ) AS avg_packing_time_days
    FROM order_items AS oi
    JOIN orders      AS o ON o.order_id = oi.order_id
    WHERE o.order_delivered_carrier_date IS NOT NULL
      AND o.order_approved_at            IS NOT NULL
    GROUP BY oi.seller_id
),

seller_category AS (            -- sales volume by category for every seller
    SELECT
        oi.seller_id,
        pct.product_category_name_english  AS category_en,
        COUNT(*)                           AS category_items
    FROM order_items                        AS oi
    JOIN products                           AS p   ON p.product_id = oi.product_id
    LEFT JOIN product_category_name_translation AS pct
         ON pct.product_category_name = p.product_category_name
    GROUP BY oi.seller_id, pct.product_category_name_english
),

seller_category_ranked AS (     -- rank categories inside every seller
    SELECT
        seller_id,
        category_en,
        category_items,
        ROW_NUMBER() OVER (
            PARTITION BY seller_id
            ORDER BY category_items DESC, category_en
        ) AS rn
    FROM seller_category
),

seller_top_cat AS (             -- keep only the best‑selling category per seller
    SELECT seller_id, category_en, category_items
    FROM   seller_category_ranked
    WHERE  rn = 1
)

SELECT
    ss.seller_id,
    ss.items_sold                         AS total_quantity_sold,
    ROUND(ss.total_sales,        4)       AS total_sales,
    ROUND(ss.avg_item_price,     4)       AS avg_item_price,
    ROUND(sr.avg_review_score,   4)       AS avg_review_score,
    ROUND(sp.avg_packing_time_days,4)     AS avg_packing_time_days,
    st.category_en                        AS top_category_english,
    st.category_items                     AS top_category_quantity
FROM            seller_sales  AS ss
JOIN            sellers       AS s  ON s.seller_id = ss.seller_id
LEFT JOIN       seller_reviews AS sr ON sr.seller_id = ss.seller_id
LEFT JOIN       seller_packing AS sp ON sp.seller_id = ss.seller_id
LEFT JOIN       seller_top_cat AS st ON st.seller_id = ss.seller_id
WHERE ss.items_sold > 100
ORDER BY ss.total_sales DESC, ss.seller_id;