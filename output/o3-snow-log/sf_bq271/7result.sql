WITH orders_2021 AS (

    /*----------------------------------------------------------------------
      Pick only the order-item rows that satisfy ALL three “happened in 2021”
      conditions:
        1.  the order itself was placed in 2021
        2.  the purchaser (user) registered in 2021
        3.  the inventory item was created (received into stock) in 2021
    ----------------------------------------------------------------------*/
    SELECT
        o."order_id",
        o."user_id",
        u."country",
        p."department",
        p."category"                AS product_category,
        p."retail_price",
        p."cost",
        /* convert micro-seconds to a month label YYYY-MM */
        TO_CHAR(
            DATE_TRUNC(
                'month',
                TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
            ),
            'YYYY-MM'
        )                           AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"          o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
      ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
      ON oi."inventory_item_id" = ii."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            u
      ON o."user_id" = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
      ON oi."product_id" = p."id"
    WHERE  YEAR(TO_TIMESTAMP_NTZ(o."created_at" / 1000000))  = 2021  -- order placed in 2021
      AND YEAR(TO_TIMESTAMP_NTZ(u."created_at" / 1000000))  = 2021  -- user registered in 2021
      AND YEAR(TO_TIMESTAMP_NTZ(ii."created_at" / 1000000)) = 2021  -- inventory item received in 2021
)

SELECT
    order_month,
    "country",
    "department",
    product_category,
    COUNT(DISTINCT "order_id")      AS number_of_orders,
    COUNT(DISTINCT "user_id")       AS unique_purchasers,
    ROUND(SUM("retail_price") - SUM("cost"), 4) AS profit
FROM orders_2021
GROUP BY
    order_month,
    "country",
    "department",
    product_category
ORDER BY
    order_month,
    "country",
    "department",
    product_category;