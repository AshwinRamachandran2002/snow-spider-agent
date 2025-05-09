WITH item_stats AS (          -- basic sales information
    SELECT  "seller_id",
            COUNT(*)                       AS "products_sold",
            SUM("price")                  AS "total_sales_value",
            AVG("price")                  AS "avg_item_price"
    FROM    "order_items"
    GROUP BY "seller_id"
    HAVING  COUNT(*) > 100                -- keep only high-volume sellers
),
review_stats AS (         -- average review score per seller
    SELECT  oi."seller_id",
            AVG(orv."review_score")       AS "avg_review_score"
    FROM    "order_items"  AS oi
    JOIN    "order_reviews" AS orv
           ON oi."order_id" = orv."order_id"
    GROUP BY oi."seller_id"
),
packing_stats AS (        -- average packing time (purchase → carrier)
    SELECT  oi."seller_id",
            AVG(julianday(o."order_delivered_carrier_date")
              - julianday(o."order_purchase_timestamp")) AS "avg_packing_days"
    FROM    "order_items" AS oi
    JOIN    "orders"      AS o
           ON oi."order_id" = o."order_id"
    GROUP BY oi."seller_id"
),
category_counts AS (      -- items sold per (seller, category)
    SELECT  oi."seller_id",
            pct."product_category_name_english"          AS "category",
            COUNT(*)                                     AS "items_in_cat"
    FROM    "order_items" AS oi
    JOIN    "products"    AS p
           ON oi."product_id" = p."product_id"
    JOIN    "product_category_name_translation" AS pct
           ON p."product_category_name" = pct."product_category_name"
    GROUP BY oi."seller_id", pct."product_category_name_english"
),
top_category AS (         -- best-selling category for each seller
    SELECT  cc."seller_id",
            cc."category"                 AS "best_selling_category",
            cc."items_in_cat"             AS "items_in_best_category"
    FROM    category_counts cc
    JOIN   (SELECT "seller_id",
                   MAX("items_in_cat") AS "max_items"
            FROM   category_counts
            GROUP BY "seller_id") mx
      ON  cc."seller_id"   = mx."seller_id"
      AND cc."items_in_cat"= mx."max_items"
)
SELECT  ists."seller_id",
        ists."products_sold",
        ROUND(ists."total_sales_value", 4)        AS "total_sales_value",
        ROUND(ists."avg_item_price",     4)        AS "avg_item_price",
        ROUND(rs."avg_review_score",     4)        AS "avg_review_score",
        ROUND(ps."avg_packing_days",     4)        AS "avg_packing_days",
        tc."best_selling_category",
        tc."items_in_best_category"
FROM    item_stats        AS ists
LEFT JOIN review_stats    AS rs  ON ists."seller_id" = rs."seller_id"
LEFT JOIN packing_stats   AS ps  ON ists."seller_id" = ps."seller_id"
LEFT JOIN top_category    AS tc  ON ists."seller_id" = tc."seller_id"
ORDER BY ists."products_sold" DESC;