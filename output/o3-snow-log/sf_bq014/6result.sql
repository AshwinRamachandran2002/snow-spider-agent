WITH valid_orders AS (               -- keep only non-cancelled / non-returned orders
    SELECT  "order_id",
            "user_id",
            "created_at"
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"
    WHERE   "status" <> 'Cancelled'
        AND "returned_at" IS NULL
),
first_valid_order AS (               -- first valid order per customer
    SELECT  "user_id",
            MIN("created_at") AS first_order_time
    FROM    valid_orders
    GROUP BY "user_id"
),
first_orders AS (                    -- the order_id(s) that are first for each customer
    SELECT  vo."order_id",
            vo."user_id"
    FROM    valid_orders vo
    JOIN    first_valid_order f
           ON f."user_id" = vo."user_id"
          AND f.first_order_time = vo."created_at"
),
first_order_categories AS (          -- categories bought in each first order
    SELECT  DISTINCT
            fo."user_id",
            p."category"
    FROM    first_orders fo
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
           ON oi."order_id" = fo."order_id"
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
           ON p."id" = oi."product_id"
    WHERE   oi."status" <> 'Cancelled'
        AND oi."returned_at" IS NULL
),
category_customer_count AS (         -- #customers whose first order contains each category
    SELECT  "category",
            COUNT(DISTINCT "user_id") AS customer_cnt
    FROM    first_order_categories
    GROUP BY "category"
),
top_category AS (                    -- category with the highest such customer count
    SELECT  "category"
    FROM    category_customer_count
    ORDER BY customer_cnt DESC NULLS LAST
    LIMIT 1
),
category_revenue AS (                -- total revenue for that top category
    SELECT  p."category",
            SUM(oi."sale_price") AS revenue
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       o
           ON o."order_id" = oi."order_id"
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
           ON p."id" = oi."product_id"
    JOIN    top_category tc
           ON tc."category" = p."category"
    WHERE   oi."status" <> 'Cancelled'
        AND oi."returned_at" IS NULL
        AND o."status" <> 'Cancelled'
        AND o."returned_at" IS NULL
    GROUP BY p."category"
)
SELECT  "category",
        ROUND(revenue, 4) AS revenue
FROM    category_revenue;