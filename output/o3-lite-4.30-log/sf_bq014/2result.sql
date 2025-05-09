WITH "first_orders" AS (               -- each shopper’s 1st valid order
    SELECT
        "user_id",
        "order_id"
    FROM (
        SELECT
            "user_id",
            "order_id",
            ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "created_at") AS rn
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
        WHERE "status" <> 'Cancelled'
          AND "returned_at" IS NULL
    )
    WHERE rn = 1
),
"first_order_items" AS (               -- items contained in those orders
    SELECT
        fo."user_id",
        oi."product_id",
        oi."sale_price"
    FROM "first_orders" fo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
          ON oi."order_id" = fo."order_id"
    WHERE oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
),
"items_with_category" AS (             -- add product category
    SELECT
        foi."user_id",
        foi."sale_price",
        p."category"
    FROM "first_order_items" foi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
          ON p."id" = foi."product_id"
),
"ranked_category" AS (                 -- category with most 1st‑order shoppers
    SELECT
        "category",
        COUNT(DISTINCT "user_id") AS "num_customers",
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "user_id") DESC) AS rnk
    FROM "items_with_category"
    GROUP BY "category"
),
"target_category" AS (
    SELECT "category"
    FROM "ranked_category"
    WHERE rnk = 1               -- keep only the top category
)
SELECT
    tc."category"       AS product_category,
    ROUND(SUM(iwc."sale_price"), 4) AS total_revenue
FROM "target_category" tc
JOIN "items_with_category" iwc
      ON iwc."category" = tc."category"
GROUP BY tc."category";