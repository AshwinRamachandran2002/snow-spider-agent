WITH Sellers AS (
    SELECT "seller_id"
    FROM "order_items"
    GROUP BY "seller_id"
    HAVING COUNT(*) > 100
),
SellerMetrics AS (
    SELECT
        oi."seller_id",
        ROUND(SUM(oi."price"), 4) AS "total_sales",
        ROUND(AVG(oi."price"), 4) AS "average_item_price",
        ROUND(AVG(orv."review_score"), 4) AS "average_review_score",
        ROUND(AVG(julianday(oi."shipping_limit_date") - julianday(o."order_approved_at")), 4) AS "packing_time"
    FROM "order_items" AS oi
    JOIN Sellers AS s ON oi."seller_id" = s."seller_id"
    JOIN "orders" AS o ON oi."order_id" = o."order_id"
    JOIN "order_reviews" AS orv ON o."order_id" = orv."order_id"
    GROUP BY oi."seller_id"
)
SELECT
    sm."seller_id",
    sm."total_sales",
    sm."average_item_price",
    sm."average_review_score",
    sm."packing_time",
    (
        SELECT t."product_category_name_english"
        FROM "order_items" AS oi2
        JOIN "products" AS p ON oi2."product_id" = p."product_id"
        JOIN "product_category_name_translation" AS t ON p."product_category_name" = t."product_category_name"
        WHERE oi2."seller_id" = sm."seller_id"
        GROUP BY t."product_category_name_english"
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS "product_category_name_english_with_highest_sales_volume"
FROM SellerMetrics AS sm;