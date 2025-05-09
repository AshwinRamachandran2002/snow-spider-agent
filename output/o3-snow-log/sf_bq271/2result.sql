WITH
/* 1.  Orders placed in 2021 */
orders_2021 AS (
    SELECT  o."order_id",
            o."user_id",
            DATE_TRUNC(
                'month',
                TO_TIMESTAMP(o."created_at" / 1000000)
            )                                 AS order_month
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"      o
    WHERE   YEAR(TO_TIMESTAMP(o."created_at" / 1000000)) = 2021
),
/* 2.  Users who registered in 2021 */
users_2021 AS (
    SELECT  u."id"          AS user_id,
            u."country"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"       u
    WHERE   YEAR(TO_TIMESTAMP(u."created_at" / 1000000)) = 2021
),
/* 3.  Inventory items created in 2021 */
inv_2021 AS (
    SELECT  ii."id"                       AS inventory_item_id,
            ii."product_department",
            ii."product_category",
            ii."product_retail_price",
            ii."cost"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
    WHERE   YEAR(TO_TIMESTAMP(ii."created_at" / 1000000)) = 2021
)
/* 4.  Assemble the final monthly report */
SELECT
        DATE_TRUNC('month', o.order_month)                               AS "month",
        u."country"                                                     AS "country",
        i."product_department"                                           AS "product_department",
        i."product_category"                                             AS "product_category",
        COUNT(DISTINCT o."order_id")                                     AS "number_of_orders",
        COUNT(DISTINCT o."user_id")                                      AS "number_of_unique_purchasers",
        ROUND(SUM(i."product_retail_price" - i."cost"), 4)               AS "profit"
FROM            orders_2021                    o
INNER JOIN      users_2021                     u   ON u.user_id             = o."user_id"
INNER JOIN      THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi  ON oi."order_id"          = o."order_id"
INNER JOIN      inv_2021                       i   ON i.inventory_item_id   = oi."inventory_item_id"
GROUP BY        DATE_TRUNC('month', o.order_month),
                u."country",
                i."product_department",
                i."product_category"
ORDER BY        "month",
                "country",
                "product_department",
                "product_category";