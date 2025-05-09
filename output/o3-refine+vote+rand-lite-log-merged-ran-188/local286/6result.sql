WITH seller_stats AS (
    SELECT
        oi."seller_id",
        COUNT(*)                                   AS "total_items_sold",
        SUM(oi."price")                            AS "total_sales_value",
        AVG(oi."price")                            AS "avg_item_price"
    FROM "order_items" AS oi
    GROUP BY oi."seller_id"
    HAVING COUNT(*) > 100
),
review_stats AS (
    SELECT
        oi."seller_id",
        AVG(r."review_score")                      AS "avg_review_score"
    FROM "order_items"  AS oi
    JOIN "order_reviews" AS r
      ON r."order_id" = oi."order_id"
    GROUP BY oi."seller_id"
),
packing_stats AS (
    SELECT
        oi."seller_id",
        AVG(julianday(o."order_delivered_carrier_date")
            - julianday(o."order_purchase_timestamp"))  AS "avg_packing_time_days"
    FROM "order_items" AS oi
    JOIN "orders"      AS o
      ON o."order_id" = oi."order_id"
    WHERE o."order_delivered_carrier_date" IS NOT NULL
    GROUP BY oi."seller_id"
),
top_category AS (
    SELECT
        oi."seller_id",
        pt."product_category_name_english"         AS "top_category_en",
        COUNT(*)                                   AS "items_in_category",
        ROW_NUMBER() OVER (
            PARTITION BY oi."seller_id"
            ORDER BY COUNT(*) DESC
        )                                          AS "rk"
    FROM "order_items" AS oi
    JOIN "products"     AS p  ON p."product_id" = oi."product_id"
    JOIN "product_category_name_translation" AS pt
         ON pt."product_category_name" = p."product_category_name"
    GROUP BY oi."seller_id", pt."product_category_name_english"
),
top_category_per_seller AS (
    SELECT
        "seller_id",
        "top_category_en",
        "items_in_category"
    FROM top_category
    WHERE "rk" = 1
)
SELECT
    s."seller_id",
    s."seller_city",
    s."seller_state",
    ss."total_items_sold",
    ROUND(ss."total_sales_value", 4)            AS "total_sales_value",
    ROUND(ss."avg_item_price", 4)               AS "avg_item_price",
    ROUND(rs."avg_review_score", 4)             AS "avg_review_score",
    ROUND(ps."avg_packing_time_days", 4)        AS "avg_packing_time_days",
    tc."top_category_en",
    tc."items_in_category"                      AS "top_category_items_sold"
FROM seller_stats              AS ss
JOIN "sellers"                  AS s  ON s."seller_id" = ss."seller_id"
LEFT JOIN review_stats          AS rs ON rs."seller_id" = ss."seller_id"
LEFT JOIN packing_stats         AS ps ON ps."seller_id" = ss."seller_id"
LEFT JOIN top_category_per_seller AS tc ON tc."seller_id" = ss."seller_id"
ORDER BY ss."total_items_sold" DESC;