WITH seller_sales AS (
    SELECT
        oi."seller_id",
        COUNT(*)                                    AS "items_sold",
        ROUND(SUM(oi."price"),4)                    AS "total_sales_value",
        ROUND(AVG(oi."price"),4)                    AS "avg_item_price"
    FROM "order_items" AS oi
    GROUP BY oi."seller_id"
    HAVING COUNT(*) > 100
),
seller_reviews AS (
    SELECT
        oi."seller_id",
        ROUND(AVG(orv."review_score"),4)            AS "avg_review_score"
    FROM   "order_items"  AS oi
    JOIN   "order_reviews" AS orv
           ON oi."order_id" = orv."order_id"
    GROUP  BY oi."seller_id"
),
seller_packing AS (
    SELECT
        oi."seller_id",
        ROUND(AVG( julianday(o."order_delivered_carrier_date")
                  - julianday(o."order_purchase_timestamp")),4)
                                                   AS "avg_packing_time_days"
    FROM   "order_items" AS oi
    JOIN   "orders"      AS o
           ON oi."order_id" = o."order_id"
    GROUP  BY oi."seller_id"
),
category_volume AS (
    SELECT
        COALESCE(t."product_category_name_english", 'unknown')
                                                   AS "product_category_name_english",
        COUNT(*)                                   AS "items_sold"
    FROM   "order_items"                          AS oi
    JOIN   "products"                             AS p
           ON oi."product_id" = p."product_id"
    LEFT JOIN "product_category_name_translation" AS t
           ON p."product_category_name" = t."product_category_name"
    GROUP  BY "product_category_name_english"
),
top_categories AS (
    SELECT *
    FROM   category_volume
    WHERE  "items_sold" = (SELECT MAX("items_sold") FROM category_volume)
)

SELECT
    ss."seller_id",
    ss."items_sold",
    ss."total_sales_value",
    ss."avg_item_price",
    sr."avg_review_score",
    sp."avg_packing_time_days",
    tc."product_category_name_english"   AS "top_product_category_english",
    tc."items_sold"                      AS "top_category_items_sold"
FROM   seller_sales   AS ss
LEFT JOIN seller_reviews AS sr
       ON ss."seller_id" = sr."seller_id"
LEFT JOIN seller_packing AS sp
       ON ss."seller_id" = sp."seller_id"
CROSS JOIN top_categories AS tc
ORDER BY ss."items_sold" DESC;