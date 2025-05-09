WITH orders_filtered AS (
    SELECT
        o."order_id",
        o."user_id",
        TO_DATE( TO_TIMESTAMP_NTZ(o."delivered_at" / 1000000) ) AS delivered_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"  u
          ON o."user_id" = u."id"
    WHERE o."status" = 'Complete'
      AND u."traffic_source" = 'Facebook'
      AND TO_DATE( TO_TIMESTAMP_NTZ(o."created_at" / 1000000) )
            BETWEEN '2022-08-01' AND '2023-11-30'
      AND o."delivered_at" IS NOT NULL
), profit_per_item AS (
    SELECT
        oi."order_id",
        (oi."sale_price" - p."cost") AS profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN orders_filtered ord
          ON oi."order_id" = ord."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
), profit_per_month AS (
    SELECT
        DATE_TRUNC('month', ord.delivered_date)               AS month_dt,
        SUM(ppi.profit)                                       AS month_profit
    FROM orders_filtered ord
    JOIN profit_per_item  ppi
          ON ord."order_id" = ppi."order_id"
    GROUP BY month_dt
    HAVING month_dt BETWEEN '2022-08-01' AND '2023-11-30'
), mom_change AS (
    SELECT
        month_dt,
        month_profit,
        month_profit
          - LAG(month_profit) OVER (ORDER BY month_dt)        AS mom_increase
    FROM profit_per_month
)
SELECT
    TO_CHAR(month_dt, 'YYYY-MM')  AS "DELIVERY_MONTH",
    ROUND(month_profit, 4)        AS "TOTAL_PROFIT",
    ROUND(mom_increase, 4)        AS "PROFIT_MOM_INCREASE"
FROM mom_change
WHERE mom_increase IS NOT NULL
ORDER BY mom_increase DESC NULLS LAST, month_dt DESC
LIMIT 5;