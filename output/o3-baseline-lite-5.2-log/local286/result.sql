WITH item_details AS (
    /* 1. Join every order‑item to its order (timestamps) and review (score) */
    SELECT
        oi.order_id,
        oi.product_id,
        oi.seller_id,
        oi.price,
        o.order_purchase_timestamp,
        o.order_delivered_carrier_date,
        r.review_score
    FROM "order_items"           AS oi
    JOIN "orders"                AS o  ON o.order_id = oi.order_id
    LEFT JOIN "order_reviews"    AS r  ON r.order_id = oi.order_id
),
item_details_ext AS (
    /* 2.  Add packing time (days) */
    SELECT
        id.*,
        (julianday(id.order_delivered_carrier_date) - julianday(id.order_purchase_timestamp))
            AS packing_time_days
    FROM item_details AS id
),
item_with_cat AS (
    /* 3.  Bring product category in English (use Portuguese as fallback) */
    SELECT
        ie.*,
        COALESCE(t.product_category_name_english , p.product_category_name)
            AS category_english
    FROM item_details_ext                    AS ie
    JOIN "products"                          AS p  ON p.product_id = ie.product_id
    LEFT JOIN "product_category_name_translation" AS t
              ON t.product_category_name = p.product_category_name
),
seller_category_qty AS (
    /* 4. Quantity sold per seller & category */
    SELECT
        seller_id,
        category_english,
        COUNT(*)  AS qty_category
    FROM item_with_cat
    GROUP BY seller_id, category_english
),
top_cat AS (
    /* 5. Pick the best‑selling category (highest qty) for every seller */
    SELECT
        seller_id,
        category_english  AS top_category_english,
        qty_category,
        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY qty_category DESC) AS rn
    FROM seller_category_qty
),
seller_perf AS (
    /* 6. Overall seller performance metrics */
    SELECT
        seller_id,
        COUNT(*)          AS total_quantity,
        SUM(price)        AS total_sales_value,
        AVG(price)        AS avg_item_price,
        AVG(review_score) AS avg_review_score,
        AVG(packing_time_days) AS avg_packing_time_days
    FROM item_with_cat
    GROUP BY seller_id
)
SELECT
    sp.seller_id,
    sp.total_quantity,
    ROUND(sp.total_sales_value,       4) AS total_sales_value,
    ROUND(sp.avg_item_price,          4) AS avg_item_price,
    ROUND(sp.avg_review_score,        4) AS avg_review_score,
    ROUND(sp.avg_packing_time_days,   4) AS avg_packing_time_days,
    tc.top_category_english,
    tc.qty_category                   AS top_category_quantity
FROM seller_perf  AS sp
JOIN top_cat      AS tc
  ON sp.seller_id = tc.seller_id AND tc.rn = 1      -- keep only the #1 category
WHERE sp.total_quantity > 100                       -- sellers with >100 items sold
ORDER BY sp.total_sales_value DESC, sp.seller_id;