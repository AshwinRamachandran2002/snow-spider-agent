WITH "GOOD_ITEMS" AS (
    SELECT 
        oi."order_id",
        oi."user_id",
        oi."sale_price",
        oi."created_at",
        p."category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON p."id" = oi."product_id"
    WHERE oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
),
"FIRST_ORDER_TIME" AS (
    SELECT 
        "user_id",
        MIN("created_at") AS "first_time"
    FROM "GOOD_ITEMS"
    GROUP BY "user_id"
),
"FIRST_ORDER_ITEMS" AS (
    SELECT g.*
    FROM "GOOD_ITEMS" g
    JOIN "FIRST_ORDER_TIME" f
          ON g."user_id" = f."user_id"
         AND g."created_at" = f."first_time"
),
"CATEGORY_CUSTOMER_COUNT" AS (
    SELECT 
        "category",
        COUNT(DISTINCT "user_id") AS "customer_count"
    FROM "FIRST_ORDER_ITEMS"
    GROUP BY "category"
),
"TOP_CATEGORY" AS (
    SELECT 
        "category"
    FROM "CATEGORY_CUSTOMER_COUNT"
    QUALIFY ROW_NUMBER() OVER (ORDER BY "customer_count" DESC NULLS LAST) = 1
),
"REVENUE_FOR_TOP_CATEGORY" AS (
    SELECT 
        SUM("sale_price") AS "revenue"
    FROM "GOOD_ITEMS" g
    JOIN "TOP_CATEGORY" t
          ON g."category" = t."category"
)
SELECT 
    t."category",
    r."revenue"
FROM "TOP_CATEGORY"               t
JOIN "REVENUE_FOR_TOP_CATEGORY"   r
      ON 1=1;