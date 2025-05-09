WITH first_orders AS (   -- first non‑cancelled / non‑returned order for every customer
    SELECT  "order_id",
            "user_id"
    FROM   (
        SELECT  "order_id",
                "user_id",
                ROW_NUMBER() OVER (PARTITION BY "user_id"
                                   ORDER BY "created_at")   AS rn
        FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
        WHERE  "status" <> 'Cancelled'
          AND  "returned_at" IS NULL
    )
    WHERE  rn = 1
),

first_order_items AS (   -- items contained in those first orders
    SELECT  fo."user_id",
            p."category"
    FROM   first_orders                                       fo
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
           ON  oi."order_id" = fo."order_id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON  p."id" = oi."product_id"
    WHERE  oi."status" <> 'Cancelled'
      AND  oi."returned_at" IS NULL
),

top_category AS (        -- category with the most such first‑order customers
    SELECT  "category"
    FROM  (
        SELECT  "category",
                COUNT(DISTINCT "user_id")            AS customer_cnt,
                ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "user_id") DESC) AS rn
        FROM    first_order_items
        GROUP BY "category"
    )
    WHERE rn = 1
)

-- revenue (sum of sale_price) for that category across all non‑cancelled/non‑returned items
SELECT  SUM(oi."sale_price") AS revenue
FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
        ON  p."id" = oi."product_id"
JOIN    top_category                                        tc
        ON  p."category" = tc."category"
WHERE   oi."status" <> 'Cancelled'
  AND   oi."returned_at" IS NULL;