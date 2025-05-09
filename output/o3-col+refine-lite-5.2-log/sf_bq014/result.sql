WITH first_orders AS (      -- each shopper’s first *good* order
    SELECT  o."user_id",
            o."order_id",
            ROW_NUMBER() OVER (PARTITION BY o."user_id"
                               ORDER BY o."created_at") AS rn
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    WHERE   o."status" NOT ILIKE '%cancel%'         -- exclude cancelled
      AND   o."status" NOT ILIKE '%return%'         -- exclude returned
),
first_items AS (           -- items contained in those first good orders
    SELECT  fo."user_id",
            fo."order_id",
            oi."product_id",
            oi."sale_price"
    FROM    first_orders  fo
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
           ON fo."order_id" = oi."order_id"
    WHERE   fo.rn = 1
      AND   oi."returned_at" IS NULL                -- drop returned items
),
category_customer AS (     -- customer count per category (first orders only)
    SELECT  p."category",
            COUNT(DISTINCT fi."user_id") AS customer_cnt
    FROM    first_items fi
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
           ON fi."product_id" = p."id"
    GROUP BY p."category"
    ORDER BY customer_cnt DESC NULLS LAST
    LIMIT 1
)
SELECT  cc."category"                                  AS "top_category",
        SUM(fi."sale_price")                           AS "revenue_in_first_orders"
FROM    category_customer  cc
JOIN    first_items        fi
       ON 1 = 1
JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
       ON fi."product_id" = p."id"
WHERE   p."category" = cc."category"
GROUP BY cc."category";