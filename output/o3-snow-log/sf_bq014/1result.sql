WITH "first_orders" AS (   -- users' first non-cancelled & non-returned orders
    SELECT 
        "user_id",
        "order_id",
        "created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" <> 'Cancelled'
      AND "returned_at" IS NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "created_at") = 1
), 

"first_order_items" AS (   -- items within those first orders
    SELECT
        fo."user_id",
        oi."sale_price",
        p."category"
    FROM "first_orders" fo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
          ON oi."order_id" = fo."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id"        = oi."product_id"
    WHERE oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
), 

"category_customer_counts" AS (   -- how many customers bought each category
    SELECT 
        "category",
        COUNT(DISTINCT "user_id") AS "customers"
    FROM "first_order_items"
    GROUP BY "category"
), 

"top_category" AS (   -- category with the most first-order customers
    SELECT "category"
    FROM   "category_customer_counts"
    ORDER BY "customers" DESC NULLS LAST
    LIMIT 1
)

SELECT 
    foi."category",
    ROUND(SUM(foi."sale_price"), 4) AS "revenue"
FROM   "first_order_items" foi
JOIN   "top_category"      tc
       ON tc."category" = foi."category"
GROUP  BY foi."category";