WITH "first_orders" AS (
    SELECT  "user_id",
            "order_id"
    FROM   (
        SELECT  "user_id",
                "order_id",
                "created_at",
                ROW_NUMBER() OVER (
                    PARTITION BY "user_id"
                    ORDER BY     "created_at"
                ) AS "rn"
        FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
        WHERE  "status" NOT ILIKE '%cancel%'      -- exclude cancelled
          AND  "returned_at" IS NULL              -- exclude returned
    ) t
    WHERE  "rn" = 1                               -- each customer’s first valid order
),
"first_items" AS (
    SELECT  fo."user_id",
            fo."order_id",
            p."category",
            oi."sale_price"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN   "first_orders"                                     fo ON oi."order_id" = fo."order_id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p  ON oi."product_id" = p."id"
),
"top_category" AS (
    SELECT  "category"
    FROM   (
        SELECT  "category",
                COUNT(DISTINCT "user_id") AS "customer_cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "user_id") DESC) AS "rnk"
        FROM    "first_items"
        GROUP BY "category"
    ) tc
    WHERE  "rnk" = 1                           -- category with most first-order customers
)
SELECT  fi."category",
        ROUND(SUM(fi."sale_price"), 4) AS "revenue"
FROM    "first_items"  fi
JOIN    "top_category" tc
  ON    fi."category" = tc."category"
GROUP BY fi."category";