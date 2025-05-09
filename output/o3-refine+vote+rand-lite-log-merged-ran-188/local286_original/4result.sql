WITH delivered_items AS (
    SELECT
        oi.seller_id,
        oi.price,
        oi.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_carrier_date,
        p.product_category_name,
        t.product_category_name_english
    FROM order_items         AS oi
    JOIN orders              AS o  ON o.order_id = oi.order_id
    LEFT JOIN products       AS p  ON p.product_id = oi.product_id
    LEFT JOIN product_category_name_translation AS t
                                   ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
),

/* --------------- core seller sales metrics ---------------- */
seller_sales AS (
    SELECT
        seller_id,
        COUNT(*)                                   AS total_quantity,
        SUM(price)                                 AS total_sales,
        AVG(price)                                 AS avg_item_price,
        AVG(
            julianday(order_delivered_carrier_date) -
            julianday(order_purchase_timestamp)
        )                                          AS avg_packing_time_days
    FROM delivered_items
    GROUP BY seller_id
    HAVING total_quantity > 100          -- only sellers with >100 items sold
),

/* --------------- average review score per seller ---------- */
seller_reviews AS (
    SELECT
        di.seller_id,
        AVG(r.review_score) AS avg_review_score
    FROM delivered_items  AS di
    JOIN order_reviews    AS r  ON r.order_id = di.order_id
    GROUP BY di.seller_id
),

/* --------------- sales volume by category ----------------- */
category_volume AS (
    SELECT
        seller_id,
        product_category_name_english AS category_en,
        COUNT(*)                      AS qty
    FROM delivered_items
    GROUP BY seller_id, product_category_name_english
),

/* --------------- pick highest‐volume category ------------- */
top_category AS (
    SELECT
        cv.seller_id,
        cv.category_en
    FROM category_volume cv
    JOIN (
        SELECT seller_id, MAX(qty) AS max_qty
        FROM category_volume
        GROUP BY seller_id
    ) m
      ON cv.seller_id = m.seller_id
     AND cv.qty       = m.max_qty
)

SELECT
    ss.seller_id,
    ss.total_quantity,
    ROUND(ss.total_sales,        2) AS total_sales,
    ROUND(ss.avg_item_price,     2) AS avg_item_price,
    ROUND(sr.avg_review_score,   2) AS avg_review_score,
    ROUND(ss.avg_packing_time_days,2) AS avg_packing_time_days,
    tc.category_en                    AS top_category_english
FROM seller_sales  AS ss
LEFT JOIN seller_reviews AS sr ON sr.seller_id = ss.seller_id
LEFT JOIN top_category   AS tc ON tc.seller_id = ss.seller_id
ORDER BY ss.total_sales DESC, ss.seller_id;