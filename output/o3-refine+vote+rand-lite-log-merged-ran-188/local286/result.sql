WITH sales AS (
    SELECT 
        "seller_id",
        COUNT(*)                          AS "items_sold",
        SUM("price")                      AS "total_sales_value",
        AVG("price")                      AS "avg_item_price"
    FROM "order_items"
    GROUP BY "seller_id"
    HAVING COUNT(*) > 100
),
reviews AS (
    SELECT 
        oi."seller_id",
        AVG(r."review_score")             AS "avg_review_score"
    FROM "order_items"  AS oi
    JOIN "order_reviews" AS r
          ON r."order_id" = oi."order_id"
    GROUP BY oi."seller_id"
),
packing AS (
    SELECT
        oi."seller_id",
        AVG(
            JULIANDAY(o."order_delivered_carrier_date") - 
            JULIANDAY(o."order_purchase_timestamp")
        )                                 AS "avg_packing_days"
    FROM "order_items" AS oi
    JOIN "orders"      AS o
          ON o."order_id" = oi."order_id"
    WHERE o."order_delivered_carrier_date" IS NOT NULL
      AND o."order_purchase_timestamp"     IS NOT NULL
    GROUP BY oi."seller_id"
),
top_cat AS (
    SELECT
        inner_q."seller_id",
        inner_q."product_category_name_english"
    FROM (
        SELECT 
            oi."seller_id",
            pct."product_category_name_english",
            COUNT(*)                                      AS cnt,
            RANK() OVER (
                PARTITION BY oi."seller_id"
                ORDER BY COUNT(*) DESC
            )                                            AS rk
        FROM "order_items" AS oi
        JOIN "products"     AS p
              ON p."product_id" = oi."product_id"
        JOIN "product_category_name_translation" AS pct
              ON pct."product_category_name" = p."product_category_name"
        GROUP BY oi."seller_id", pct."product_category_name_english"
    ) inner_q
    WHERE inner_q.rk = 1
)
SELECT 
    s."seller_id",
    s."seller_city",
    s."seller_state",
    sales."items_sold",
    ROUND(sales."total_sales_value", 4)   AS "total_sales_value",
    ROUND(sales."avg_item_price", 4)      AS "avg_item_price",
    ROUND(reviews."avg_review_score", 4)  AS "avg_review_score",
    ROUND(packing."avg_packing_days", 4)  AS "avg_packing_days",
    top_cat."product_category_name_english" AS "top_category_eng"
FROM "sellers" AS s
JOIN sales   ON sales."seller_id"   = s."seller_id"
LEFT JOIN reviews ON reviews."seller_id" = s."seller_id"
LEFT JOIN packing ON packing."seller_id" = s."seller_id"
LEFT JOIN top_cat ON top_cat."seller_id" = s."seller_id"
ORDER BY sales."items_sold" DESC;