WITH base AS (
    SELECT
        o."order_id",
        o."user_id",
        u."country",
        p."department",
        p."category",
        p."retail_price",
        p."cost",
        DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000)) AS "order_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"          o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"           u   ON u."id"  = o."user_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi  ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" inv ON inv."id" = oi."inventory_item_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p   ON p."id"  = oi."product_id"
    WHERE o."created_at"  BETWEEN 1609459200000000 AND 1640995199000000  -- orders in 2021
      AND u."created_at"  BETWEEN 1609459200000000 AND 1640995199000000  -- users registered 2021
      AND inv."created_at" BETWEEN 1609459200000000 AND 1640995199000000 -- inventory items created 2021
)
SELECT
    "order_month",
    "country",
    "department",
    "category",
    COUNT(DISTINCT "order_id")  AS "num_orders",
    COUNT(DISTINCT "user_id")   AS "unique_purchasers",
    ROUND(SUM("retail_price" - "cost"), 4) AS "profit"
FROM base
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