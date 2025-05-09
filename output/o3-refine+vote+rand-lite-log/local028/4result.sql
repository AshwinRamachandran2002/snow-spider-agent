WITH RECURSIVE
    months(month) AS (               -- generate the 12 months
        SELECT 1
        UNION ALL
        SELECT month + 1 FROM months WHERE month < 12
    ),
    orders_per_month AS (            -- delivered‑order counts by year & month
        SELECT
            CAST(strftime('%m', "order_delivered_customer_date") AS INTEGER) AS month,
            CAST(strftime('%Y', "order_delivered_customer_date") AS INTEGER) AS year,
            COUNT(*) AS delivered_cnt
        FROM "olist_orders"
        WHERE "order_status" = 'delivered'
          AND "order_delivered_customer_date" IS NOT NULL
          AND strftime('%Y', "order_delivered_customer_date") IN ('2016','2017','2018')
        GROUP BY year, month
    )
SELECT
    m.month,
    COALESCE(SUM(CASE WHEN opm.year = 2016 THEN opm.delivered_cnt END), 0) AS "2016",
    COALESCE(SUM(CASE WHEN opm.year = 2017 THEN opm.delivered_cnt END), 0) AS "2017",
    COALESCE(SUM(CASE WHEN opm.year = 2018 THEN opm.delivered_cnt END), 0) AS "2018"
FROM months AS m
LEFT JOIN orders_per_month AS opm
       ON opm.month = m.month
GROUP BY m.month
ORDER BY m.month;