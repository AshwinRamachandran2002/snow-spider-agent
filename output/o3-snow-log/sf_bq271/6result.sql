WITH filtered AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."created_at" / 1000000.0))      AS month_start,
        u."country",
        p."department",
        p."category",
        o."order_id",
        o."user_id",
        (p."retail_price" - p."cost")                                         AS profit_component
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"            o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"             u  ON o."user_id"          = u."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"       oi ON o."order_id"         = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"   ii ON oi."inventory_item_id"= ii."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"          p  ON oi."product_id"      = p."id"
    WHERE
          TO_TIMESTAMP_LTZ(o."created_at" / 1000000.0) BETWEEN '2021-01-01' AND '2021-12-31 23:59:59.999'
      AND TO_TIMESTAMP_LTZ(u."created_at" / 1000000.0) BETWEEN '2021-01-01' AND '2021-12-31 23:59:59.999'
      AND TO_TIMESTAMP_LTZ(ii."created_at"/ 1000000.0) BETWEEN '2021-01-01' AND '2021-12-31 23:59:59.999'
)

SELECT
    TO_CHAR(month_start, 'YYYY-MM')                    AS "month",
    "country",
    "department",
    "category",
    COUNT(DISTINCT "order_id")                        AS "num_orders",
    COUNT(DISTINCT "user_id")                         AS "num_unique_purchasers",
    ROUND(SUM(profit_component), 4)                   AS "profit"
FROM filtered
GROUP BY
    month_start,
    "country",
    "department",
    "category"
ORDER BY
    month_start,
    "country",
    "department",
    "category";