WITH order_details AS (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
        )                                   AS "order_month",
        u."country"                         AS "country",
        ii."product_department"             AS "product_department",
        ii."product_category"               AS "product_category",
        o."order_id"                        AS "order_id",
        u."id"                              AS "user_id",
        ii."product_retail_price"           AS "product_retail_price",
        ii."cost"                           AS "product_cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS          o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS     oi
         ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS ii
         ON ii."id" = oi."inventory_item_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS           u
         ON u."id" = o."user_id"
    WHERE YEAR(TO_TIMESTAMP_NTZ(o."created_at"  / 1000000)) = 2021   -- orders placed in 2021
      AND YEAR(TO_TIMESTAMP_NTZ(u."created_at"  / 1000000)) = 2021   -- users registered in 2021
      AND YEAR(TO_TIMESTAMP_NTZ(ii."created_at" / 1000000)) = 2021   -- inventory items created in 2021
)

SELECT
    "order_month",
    "country",
    "product_department",
    "product_category",
    COUNT(DISTINCT "order_id")  AS "num_orders",
    COUNT(DISTINCT "user_id")   AS "num_unique_purchasers",
    ROUND(SUM("product_retail_price" - "product_cost"), 4) AS "profit"
FROM order_details
GROUP BY
    "order_month",
    "country",
    "product_department",
    "product_category"
ORDER BY
    "order_month",
    "country",
    "product_department",
    "product_category";