WITH facebook_orders AS (
    /* Orders whose customers originally came from Facebook
       and were created between 1‑Aug‑2022 and 30‑Nov‑2023 */
    SELECT  o."order_id"
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"  o
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"   u
           ON o."user_id" = u."id"
    WHERE   u."traffic_source" = 'Facebook'
      AND   TO_DATE(TO_TIMESTAMP_NTZ(o."created_at" / 1000000))
            BETWEEN '2022-08-01' AND '2023-11-30'
), item_level_profit AS (
    /* Profit for every completed order‑item coming from the
       Facebook orders identified above */
    SELECT  DATE_TRUNC('month',
                       TO_TIMESTAMP_NTZ(oi."delivered_at" / 1000000)
                      )                                                   AS delivered_month ,
            (oi."sale_price" - ii."cost")                                 AS profit
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN    facebook_orders                                              fb
           ON oi."order_id" = fb."order_id"
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" ii
           ON oi."inventory_item_id" = ii."id"
    WHERE   oi."status" = 'Complete'
      AND   oi."delivered_at" IS NOT NULL
), monthly_profit AS (
    /* Total profit per delivery month within the period */
    SELECT  delivered_month ,
            SUM(profit) AS month_profit
    FROM    item_level_profit
    GROUP BY delivered_month
    HAVING  delivered_month BETWEEN '2022-08-01'::date
                               AND     '2023-11-30'::date
), profit_with_change AS (
    /* Month‑over‑month profit change */
    SELECT  delivered_month ,
            month_profit ,
            month_profit
            - LAG(month_profit) OVER (ORDER BY delivered_month) AS mom_increase
    FROM    monthly_profit
)
SELECT  TO_CHAR(delivered_month, 'YYYY-MM')          AS "MONTH" ,
        ROUND(month_profit,      4)                  AS "PROFIT" ,
        ROUND(mom_increase,      4)                  AS "MONTH_OVER_MONTH_INCREASE"
FROM    profit_with_change
WHERE   mom_increase IS NOT NULL
ORDER BY mom_increase DESC NULLS LAST , delivered_month
LIMIT 5;