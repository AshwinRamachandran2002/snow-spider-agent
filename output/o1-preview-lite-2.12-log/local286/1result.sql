WITH seller_stats AS (
    SELECT "seller_id",
           ROUND(SUM("price"), 4) AS "total_sales",
           ROUND(AVG("price"), 4) AS "average_item_price"
    FROM "order_items"
    GROUP BY "seller_id"
    HAVING COUNT("order_item_id") > 100
),
seller_reviews AS (
    SELECT oi."seller_id",
           ROUND(AVG(orv."review_score"), 4) AS "average_review_score"
    FROM "order_items" AS oi
    JOIN "orders" AS o ON oi."order_id" = o."order_id"
    JOIN "order_reviews" AS orv ON o."order_id" = orv."order_id"
    GROUP BY oi."seller_id"
),
seller_packing_time AS (
    SELECT oi."seller_id",
           ROUND(AVG(JULIANDAY(o."order_delivered_carrier_date") - JULIANDAY(o."order_purchase_timestamp")), 4) AS "packing_time"
    FROM "order_items" AS oi
    JOIN "orders" AS o ON oi."order_id" = o."order_id"
    WHERE o."order_delivered_carrier_date" IS NOT NULL AND o."order_purchase_timestamp" IS NOT NULL
    GROUP BY oi."seller_id"
),
seller_category_ranked AS (
    SELECT
        oi."seller_id",
        pct."product_category_name_english" AS "product_category_name_english_with_highest_sales_volume",
        RANK() OVER (
            PARTITION BY oi."seller_id"
            ORDER BY COUNT(oi."order_item_id") DESC
        ) AS "category_rank"
    FROM "order_items" AS oi
    JOIN "products" AS p ON oi."product_id" = p."product_id"
    JOIN "product_category_name_translation" AS pct ON p."product_category_name" = pct."product_category_name"
    GROUP BY oi."seller_id", pct."product_category_name_english"
)
SELECT
    ss."seller_id",
    ss."total_sales",
    ss."average_item_price",
    sr."average_review_score",
    sp."packing_time",
    scr."product_category_name_english_with_highest_sales_volume"
FROM seller_stats AS ss
LEFT JOIN seller_reviews AS sr ON ss."seller_id" = sr."seller_id"
LEFT JOIN seller_packing_time AS sp ON ss."seller_id" = sp."seller_id"
LEFT JOIN (
    SELECT "seller_id", "product_category_name_english_with_highest_sales_volume"
    FROM seller_category_ranked
    WHERE "category_rank" = 1
) AS scr ON ss."seller_id" = scr."seller_id";