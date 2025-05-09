WITH "first_orders" AS (   -- keep only the first valid (non‑cancelled & non‑returned) order per customer
    SELECT
        "user_id",
        "order_id",
        ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "created_at") AS "rn"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" <> 'Cancelled'
      AND "returned_at" IS NULL
),
"first_valid_orders" AS (
    SELECT "user_id", "order_id"
    FROM "first_orders"
    WHERE "rn" = 1
),
"category_customer_counts" AS (   -- count how many customers bought each category in their first order
    SELECT
        p."category",
        COUNT(DISTINCT fvo."user_id") AS "customer_cnt"
    FROM "first_valid_orders"            fvo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
           ON oi."order_id" = fvo."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON p."id" = oi."product_id"
    WHERE oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
    GROUP BY p."category"
),
"top_category" AS (         -- category with the highest customer count
    SELECT "category"
    FROM "category_customer_counts"
    ORDER BY "customer_cnt" DESC NULLS LAST, "category"
    LIMIT 1
),
"revenue_top_category" AS ( -- total revenue for that category (all valid sales)
    SELECT
        p."category",
        SUM(oi."sale_price") AS "revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE p."category" IN (SELECT "category" FROM "top_category")
      AND oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
    GROUP BY p."category"
)
SELECT
    "category",
    ROUND("revenue", 4) AS "revenue"
FROM "revenue_top_category";