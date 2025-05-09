WITH item_data AS (
    /* every item sold, enriched with its English category name */
    SELECT
        oi.seller_id,
        oi.order_id,
        oi.price,
        1                                                AS qty,
        pct.product_category_name_english               AS category_en
    FROM   order_items                           AS oi
    JOIN   products                               AS p   ON p.product_id = oi.product_id
    LEFT   JOIN product_category_name_translation AS pct ON pct.product_category_name = p.product_category_name
),
/* core sales metrics -------------------------------------------------------*/
seller_sales AS (
    SELECT
        seller_id,
        COUNT(*)                              AS total_products_sold,
        SUM(price)                            AS total_sales_value,
        AVG(price)                            AS avg_item_price
    FROM item_data
    GROUP BY seller_id
),
/* review score per seller --------------------------------------------------*/
seller_reviews AS (
    SELECT
        oi.seller_id,
        AVG(orv.review_score) AS avg_review_score
    FROM   order_items  AS oi
    JOIN   order_reviews AS orv ON orv.order_id = oi.order_id
    GROUP BY oi.seller_id
),
/* packing‑time (approved → handed to carrier) ------------------------------*/
seller_pack_time AS (
    SELECT
        oi.seller_id,
        AVG( (julianday(o.order_delivered_carrier_date) -
              julianday(o.order_approved_at)) * 24 ) AS avg_packing_hours
    FROM   order_items AS oi
    JOIN   orders      AS o ON o.order_id = oi.order_id
    WHERE  o.order_delivered_carrier_date IS NOT NULL
       AND o.order_approved_at            IS NOT NULL
    GROUP BY oi.seller_id
),
/* find each seller’s top‑selling English category --------------------------*/
seller_category_qty AS (
    SELECT
        seller_id,
        category_en,
        SUM(qty) AS cat_qty
    FROM item_data
    GROUP BY seller_id, category_en
),
seller_top_category AS (
    SELECT
        seller_id,
        category_en,
        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY cat_qty DESC) AS rn
    FROM seller_category_qty
)
/* final report -------------------------------------------------------------*/
SELECT
    ss.seller_id,
    ss.total_products_sold,
    ROUND(ss.total_sales_value, 4)  AS total_sales_value,
    ROUND(ss.avg_item_price, 4)     AS avg_item_price,
    ROUND(sr.avg_review_score, 4)   AS avg_review_score,
    ROUND(sp.avg_packing_hours, 4)  AS avg_packing_hours,
    stc.category_en                 AS top_category_english
FROM   seller_sales          AS ss
LEFT   JOIN seller_reviews    AS sr  ON sr.seller_id  = ss.seller_id
LEFT   JOIN seller_pack_time  AS sp  ON sp.seller_id  = ss.seller_id
LEFT   JOIN seller_top_category AS stc
       ON stc.seller_id = ss.seller_id AND stc.rn = 1   -- keep best category
WHERE  ss.total_products_sold > 100
ORDER BY ss.total_products_sold DESC,
         ss.seller_id;