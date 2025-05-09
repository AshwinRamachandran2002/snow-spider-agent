WITH RECURSIVE months(month) AS (
    SELECT 1
    UNION ALL
    SELECT month + 1 FROM months WHERE month < 12
),
delivered AS (
    SELECT
        CAST(strftime('%Y', "order_delivered_customer_date") AS INTEGER) AS yr,
        CAST(strftime('%m', "order_delivered_customer_date") AS INTEGER) AS mn
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND "order_delivered_customer_date" IS NOT NULL
      AND strftime('%Y', "order_delivered_customer_date") IN ('2016','2017','2018')
)
SELECT
    m.month                                    AS "month",
    SUM(CASE WHEN d.yr = 2016 THEN 1 ELSE 0 END) AS "2016",
    SUM(CASE WHEN d.yr = 2017 THEN 1 ELSE 0 END) AS "2017",
    SUM(CASE WHEN d.yr = 2018 THEN 1 ELSE 0 END) AS "2018"
FROM months AS m
LEFT JOIN delivered AS d
       ON d.mn = m.month
GROUP BY m.month
ORDER BY m.month;