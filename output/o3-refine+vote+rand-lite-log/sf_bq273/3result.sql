/*  Top‑5 months (Aug‑2022 – Nov‑2023) with the largest MoM profit jump
    for Facebook‑sourced, completed orders
*/
WITH orders_filtered AS (
    SELECT
        oi."id"                                    AS order_item_id ,
        oi."sale_price"                            AS sale_price   ,
        p."cost"                                   AS cost         ,
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."delivered_at" / 1e6)
        )                                          AS delivery_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       o
          ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"        u
          ON u."id" = o."user_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE   oi."status"       = 'Complete'
        AND u."traffic_source"= 'Facebook'
        AND o."created_at"    >= (DATEDIFF(second , '1970-01-01' , '2022-08-01') * 1e6)
        AND o."created_at"    <  (DATEDIFF(second , '1970-01-01' , '2023-12-01') * 1e6)
        AND oi."delivered_at" IS NOT NULL
),
monthly_profit AS (
    SELECT
        delivery_month ,
        SUM(sale_price - cost)      AS profit
    FROM orders_filtered
    GROUP BY delivery_month
),
mom_change AS (
    SELECT
        delivery_month ,
        profit ,
        LAG(profit)  OVER (ORDER BY delivery_month)              AS prev_profit ,
        profit - LAG(profit) OVER (ORDER BY delivery_month)       AS profit_increase
    FROM monthly_profit
)
SELECT
    TO_CHAR(delivery_month, 'YYYY-MM')        AS month ,
    ROUND(prev_profit      , 4)               AS previous_month_profit ,
    ROUND(profit           , 4)               AS current_month_profit ,
    ROUND(profit_increase  , 4)               AS profit_increase
FROM   mom_change
WHERE  delivery_month BETWEEN '2022-08-01' AND '2023-11-30'
ORDER  BY profit_increase DESC NULLS LAST , delivery_month
LIMIT  5;