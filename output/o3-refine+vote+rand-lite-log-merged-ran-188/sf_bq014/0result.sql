WITH first_good_orders AS (   -- each customer's first non-cancelled & non-returned order
    SELECT
        "user_id",
        "order_id"
    FROM (
        SELECT
            "user_id",
            "order_id",
            ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "created_at") AS rn
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
        WHERE "status" NOT ILIKE '%cancel%'      -- exclude Cancelled
          AND "returned_at" IS NULL              -- exclude Returned
    )
    WHERE rn = 1
),
items_with_cat AS (           -- bring in items & product category
    SELECT
        fgo."user_id",
        p."category",
        oi."sale_price"
    FROM first_good_orders                         fgo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
      ON oi."order_id" = fgo."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
      ON p."id"        = oi."product_id"
),
category_rank AS (            -- find category with most first-order customers
    SELECT
        "category",
        COUNT(DISTINCT "user_id")                           AS "num_customers",
        RANK() OVER (ORDER BY COUNT(DISTINCT "user_id") DESC) AS rnk
    FROM items_with_cat
    GROUP BY "category"
)
SELECT
    iwc."category"                        AS "top_category",
    ROUND(SUM(iwc."sale_price"), 4)       AS "revenue_first_orders"
FROM items_with_cat      iwc
JOIN category_rank       cr
  ON cr."category" = iwc."category"
WHERE cr.rnk = 1                          -- keep only the top category
GROUP BY iwc."category";