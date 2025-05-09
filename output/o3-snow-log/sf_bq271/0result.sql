WITH qualifying_items AS (
    SELECT
        OI."order_id",
        OI."user_id",
        TO_TIMESTAMP(O."created_at" / 1000000)              AS order_ts,
        TO_TIMESTAMP(U."created_at" / 1000000)              AS user_signup_ts,
        TO_TIMESTAMP(II."created_at" / 1000000)             AS item_created_ts,
        P."department",
        P."category",
        U."country",
        P."retail_price",
        P."cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS        OI
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS             O
         ON O."order_id" = OI."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS              U
         ON U."id" = O."user_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS    II
         ON II."id" = OI."inventory_item_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS           P
         ON P."id" = OI."product_id"
    WHERE  EXTRACT(year FROM TO_TIMESTAMP(O."created_at"  / 1000000))  = 2021   -- orders placed in 2021
       AND EXTRACT(year FROM TO_TIMESTAMP(U."created_at" / 1000000))  = 2021   -- users registered in 2021
       AND EXTRACT(year FROM TO_TIMESTAMP(II."created_at" / 1000000)) = 2021   -- inventory items created in 2021
)

SELECT
    TO_CHAR(DATE_TRUNC('month', order_ts), 'YYYY-MM')      AS "order_month",
    "country",
    "department",
    "category",
    COUNT(DISTINCT "order_id")                             AS "orders_count",
    COUNT(DISTINCT "user_id")                              AS "unique_purchasers",
    SUM("retail_price") - SUM("cost")                      AS "profit"
FROM qualifying_items
GROUP BY
    "order_month",
    "country",
    "department",
    "category"
ORDER BY
    "order_month",
    "country",
    "department",
    "category";