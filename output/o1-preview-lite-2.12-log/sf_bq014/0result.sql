WITH NonCancelledOrders AS (
    SELECT "order_id", "user_id", "created_at"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"
    WHERE "status" NOT IN ('Cancelled', 'Returned')
),
FirstOrders AS (
    SELECT "user_id", MIN("created_at") AS "first_order_created_at"
    FROM NonCancelledOrders
    GROUP BY "user_id"
),
UserFirstOrders AS (
    SELECT nco."user_id", nco."order_id"
    FROM NonCancelledOrders nco
    INNER JOIN FirstOrders fo
        ON nco."user_id" = fo."user_id"
       AND nco."created_at" = fo."first_order_created_at"
),
FirstOrderItems AS (
    SELECT oi."user_id", oi."product_id", oi."sale_price"
    FROM UserFirstOrders ufo
    INNER JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
        ON ufo."order_id" = oi."order_id"
    WHERE oi."status" NOT IN ('Cancelled', 'Returned')
),
OrderItemsWithCategory AS (
    SELECT foi."user_id", foi."sale_price", p."category"
    FROM FirstOrderItems foi
    INNER JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
        ON foi."product_id" = p."id"
)
SELECT oiwc."category" AS "Product_Category",
       ROUND(SUM(oiwc."sale_price"), 4) AS "Revenue"
FROM OrderItemsWithCategory oiwc
GROUP BY oiwc."category"
ORDER BY COUNT(DISTINCT oiwc."user_id") DESC NULLS LAST
LIMIT 1;