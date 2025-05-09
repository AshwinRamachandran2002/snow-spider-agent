/*  Monthly 2021 performance by country × department × category
    – only orders placed in 2021
    – only users who first registered in 2021
    – only inventory items first stocked in 2021
*/
WITH
    /* Users who registered in 2021 */
    "users_2021" AS (
        SELECT
            "id"      AS "user_id",
            "country"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
        WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000))
              BETWEEN '2021-01-01' AND '2021-12-31'
    ),

    /* Orders created in 2021 */
    "orders_2021" AS (
        SELECT
            "order_id",
            "user_id",
            TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) AS "order_date"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
        WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000))
              BETWEEN '2021-01-01' AND '2021-12-31'
    ),

    /* Inventory items first stocked in 2021 */
    "inventory_2021" AS (
        SELECT
            "id"                       AS "inventory_item_id",
            "cost",
            "product_retail_price",
            "product_department",
            "product_category"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS
        WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000))
              BETWEEN '2021-01-01' AND '2021-12-31'
    ),

    /* Order‑item links limited to the 2021 orders above */
    "order_items_stage" AS (
        SELECT
            oi."order_id",
            oi."user_id",
            oi."inventory_item_id"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
        JOIN "orders_2021"                                      o
              ON o."order_id" = oi."order_id"
    )

/* Final aggregation */
SELECT
    TO_CHAR(o."order_date", 'YYYY-MM')                    AS "order_month",
    u."country",
    inv."product_department",
    inv."product_category",
    COUNT(DISTINCT o."order_id")                          AS "num_orders",
    COUNT(DISTINCT o."user_id")                           AS "num_unique_purchasers",
    ROUND(SUM(inv."product_retail_price" - inv."cost"), 4) AS "profit"
FROM "order_items_stage"        oi
JOIN "orders_2021"              o    ON o."order_id"          = oi."order_id"
JOIN "users_2021"               u    ON u."user_id"           = o."user_id"
JOIN "inventory_2021"           inv  ON inv."inventory_item_id" = oi."inventory_item_id"
GROUP BY
    TO_CHAR(o."order_date", 'YYYY-MM'),
    u."country",
    inv."product_department",
    inv."product_category"
ORDER BY
    "order_month",
    u."country",
    inv."product_department",
    inv."product_category";