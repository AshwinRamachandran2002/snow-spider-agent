WITH first_valid_orders AS (            -- each customer’s first non-cancelled & non-returned order
    SELECT  o."order_id",
            o."user_id"
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
    WHERE   o."status" NOT ILIKE '%cancel%'      -- exclude cancelled orders
      AND   o."returned_at" IS NULL              -- exclude orders already returned
    QUALIFY ROW_NUMBER() OVER (PARTITION BY o."user_id"
                               ORDER BY o."created_at") = 1
),
first_order_items AS (                  -- items belonging to those first orders
    SELECT  fvo."user_id",
            oi."product_id",
            oi."sale_price"
    FROM    first_valid_orders fvo
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
           ON oi."order_id" = fvo."order_id"
    WHERE   oi."returned_at" IS NULL               -- drop items individually returned
),
items_with_category AS (                -- attach product category
    SELECT  foi."user_id",
            p."category",
            foi."sale_price"
    FROM    first_order_items foi
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
           ON p."id" = foi."product_id"
),
top_category AS (                       -- category with the most first-time customers
    SELECT  "category"
    FROM    items_with_category
    GROUP BY "category"
    ORDER BY COUNT(DISTINCT "user_id") DESC NULLS LAST
    LIMIT 1
)
SELECT  iwc."category",
        ROUND(SUM(iwc."sale_price"), 4) AS "revenue"
FROM    items_with_category  iwc
JOIN    top_category         tc
      ON iwc."category" = tc."category"
GROUP BY iwc."category";