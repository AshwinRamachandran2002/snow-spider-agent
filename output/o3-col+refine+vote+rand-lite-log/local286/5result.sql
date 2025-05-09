WITH seller_sales AS (
    /* 1) Sellers with >100 items sold: total qty + avg price */
    SELECT
        oi."seller_id",
        COUNT(*)                         AS "total_items_sold",
        AVG(oi."price")                  AS "avg_item_price"
    FROM "order_items" AS oi
    GROUP BY oi."seller_id"
    HAVING COUNT(*) > 100
),
seller_reviews AS (
    /* 2) Average review score per seller (only orders that have reviews) */
    SELECT
        oi."seller_id",
        AVG(orv."review_score")          AS "avg_review_score"
    FROM "order_items"  AS oi
    JOIN "order_reviews" AS orv
          ON orv."order_id" = oi."order_id"
    GROUP BY oi."seller_id"
),
seller_packing AS (
    /* 3) Average packing time (approval ➜ carrier dispatch) in days */
    SELECT
        oi."seller_id",
        AVG(
            julianday(o."order_delivered_carrier_date")
          - julianday(o."order_approved_at")
        )                                AS "avg_packing_time_days"
    FROM "order_items" AS oi
    JOIN "orders"      AS o
          ON o."order_id" = oi."order_id"
    WHERE o."order_approved_at" IS NOT NULL
      AND o."order_delivered_carrier_date" IS NOT NULL
    GROUP BY oi."seller_id"
),
top_categories AS (
    /* 4) Top-5 product categories in English by overall volume */
    SELECT
        pct."product_category_name_english",
        COUNT(*)                         AS "total_items_sold"
    FROM "order_items"                       AS oi
    JOIN "products"                          AS p
          ON p."product_id" = oi."product_id"
    JOIN "product_category_name_translation" AS pct
          ON pct."product_category_name" = p."product_category_name"
    GROUP BY pct."product_category_name_english"
    ORDER BY "total_items_sold" DESC
    LIMIT 5
),
top_cat_list AS (
    /* 5) One comma-separated string with the highlighted categories */
    SELECT group_concat("product_category_name_english", ', ') AS "top_categories"
    FROM   top_categories
)

SELECT
    ss."seller_id",
    ss."total_items_sold",
    ROUND(ss."avg_item_price",       4) AS "avg_item_price",
    ROUND(sr."avg_review_score",     4) AS "avg_review_score",
    ROUND(sp."avg_packing_time_days",4) AS "avg_packing_time_days",
    tcl."top_categories"                 /* highlighted best-selling categories */
FROM  seller_sales  AS ss
LEFT  JOIN seller_reviews AS sr ON sr."seller_id" = ss."seller_id"
LEFT  JOIN seller_packing AS sp ON sp."seller_id" = ss."seller_id"
CROSS JOIN top_cat_list AS tcl
ORDER BY ss."total_items_sold" DESC;