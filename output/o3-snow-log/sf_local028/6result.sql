/* Delivered orders per month for 2016-2018 */

WITH delivered_orders AS (      -- delivered orders in the three required years
    SELECT
        EXTRACT(YEAR  FROM delivered_ts)  AS yr,
        EXTRACT(MONTH FROM delivered_ts)  AS mon
    FROM (
        SELECT
            TRY_TO_TIMESTAMP("order_delivered_customer_date") AS delivered_ts,
            "order_status"
        FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    )
    WHERE "order_status" = 'delivered'
      AND delivered_ts IS NOT NULL
      AND EXTRACT(YEAR FROM delivered_ts) IN (2016, 2017, 2018)
),
months AS (                     -- generate rows for the 12 calendar months
    SELECT SEQ4() + 1 AS mon
    FROM   TABLE(GENERATOR(ROWCOUNT => 12))
)

SELECT
       m.mon                                                       AS "month",
       COALESCE(SUM(CASE WHEN d.yr = 2016 THEN 1 END), 0)          AS "2016",
       COALESCE(SUM(CASE WHEN d.yr = 2017 THEN 1 END), 0)          AS "2017",
       COALESCE(SUM(CASE WHEN d.yr = 2018 THEN 1 END), 0)          AS "2018"
FROM   months m
LEFT  JOIN delivered_orders d
       ON m.mon = d.mon
GROUP BY m.mon
ORDER BY m.mon;