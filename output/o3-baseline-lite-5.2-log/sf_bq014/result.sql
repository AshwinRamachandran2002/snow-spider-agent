WITH "FIRST_VALID_ORDERS" AS (                         -- 1. each shopper’s 1st kept order
    SELECT
        "user_id",
        "order_id"
    FROM (
        SELECT
            "user_id",
            "order_id",
            "created_at",
            ROW_NUMBER() OVER (PARTITION BY "user_id"
                               ORDER BY "created_at") AS "rn"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
        WHERE "status" <> 'Cancelled'
          AND "returned_at" IS NULL
    )
    WHERE "rn" = 1
),
"FIRST_ORDER_ITEMS" AS (                               -- 2. items actually kept in those orders
    SELECT
        fvo."user_id",
        oi."order_id",
        oi."product_id",
        oi."sale_price"
    FROM "FIRST_VALID_ORDERS"     fvo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
         ON oi."order_id" = fvo."order_id"
        AND oi."user_id"  = fvo."user_id"
    WHERE oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
),
"CATEGORY_STATS" AS (                                  -- 3. customers count & revenue by category
    SELECT
        p."category"                        AS "product_category",
        COUNT(DISTINCT foi."user_id")       AS "customers_cnt",
        SUM(foi."sale_price")               AS "category_revenue"
    FROM "FIRST_ORDER_ITEMS"  foi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
         ON p."id" = foi."product_id"
    GROUP BY p."category"
),
"TOP_CATEGORY" AS (                                    -- 4. category with most first‑order shoppers
    SELECT
        "product_category",
        "category_revenue"
    FROM "CATEGORY_STATS"
    QUALIFY ROW_NUMBER() OVER (ORDER BY "customers_cnt" DESC,
                                         "product_category") = 1
)
SELECT
    "product_category",
    ROUND("category_revenue", 4)  AS "revenue"
FROM "TOP_CATEGORY";