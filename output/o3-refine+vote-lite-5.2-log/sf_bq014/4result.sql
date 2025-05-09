WITH first_successful_orders AS (          -- first non‑cancelled, non‑returned order per customer
    SELECT
        "user_id",
        "order_id"
    FROM (
        SELECT
            "user_id",
            "order_id",
            ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "created_at") AS rn
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
        WHERE "status" <> 'Cancelled'
          AND "returned_at" IS NULL
    )
    WHERE rn = 1
),
first_order_items AS (                     -- items in those first successful orders
    SELECT
        f."user_id",
        p."category",
        oi."sale_price"
    FROM first_successful_orders                               f
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi ON f."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p  ON oi."product_id" = p."id"
    WHERE oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
),
cat_stats AS (                             -- customers and revenue by product category
    SELECT
        "category",
        COUNT(DISTINCT "user_id")                               AS "CUSTOMER_COUNT",
        SUM("sale_price")                                       AS "REVENUE",
        RANK() OVER (ORDER BY COUNT(DISTINCT "user_id") DESC)   AS rnk
    FROM first_order_items
    GROUP BY "category"
)
SELECT
    "category",
    ROUND("REVENUE", 4) AS "revenue"
FROM cat_stats
WHERE rnk = 1;