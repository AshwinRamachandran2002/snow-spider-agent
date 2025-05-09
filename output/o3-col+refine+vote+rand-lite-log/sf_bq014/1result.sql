WITH first_orders AS (  -- each shopper’s first *non-cancelled* order
    SELECT 
        o."user_id",
        MIN(o."created_at") AS "first_good_order_created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    WHERE o."status" NOT ILIKE '%cancel%'
    GROUP BY o."user_id"
),

first_order_items AS (  -- items (and categories) that belong to those first orders
    SELECT
        fo."user_id",
        oi."order_id",
        p."category",
        oi."sale_price"
    FROM first_orders fo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
         ON o."user_id"    = fo."user_id"
        AND o."created_at" = fo."first_good_order_created_at"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
         ON oi."order_id"  = o."order_id"
        AND oi."status"    NOT ILIKE '%cancel%'
        AND oi."returned_at" IS NULL
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
         ON p."id" = oi."product_id"
),

top_category AS (       -- find the category with the most distinct customers
    SELECT
        ranked."category"
    FROM (
        SELECT
            foi."category",
            COUNT(DISTINCT foi."user_id")                       AS "cust_cnt",
            ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT foi."user_id") DESC) AS "rn"
        FROM first_order_items foi
        GROUP BY foi."category"
    ) ranked
    WHERE ranked."rn" = 1
)

SELECT
    foi."category",
    SUM(foi."sale_price") AS "total_revenue_top_category"
FROM first_order_items foi
JOIN top_category tc
  ON tc."category" = foi."category"
GROUP BY foi."category";