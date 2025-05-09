WITH delivered_per_month AS (
    /* 1. Count delivered orders per month & year (2016‑2018) */
    SELECT 
        CAST(strftime('%m', "order_delivered_customer_date") AS INTEGER) AS month,
        strftime('%Y', "order_delivered_customer_date")                  AS year,
        COUNT(*)                                                        AS cnt
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND "order_delivered_customer_date" IS NOT NULL
      AND strftime('%Y', "order_delivered_customer_date") IN ('2016','2017','2018')
    GROUP BY year, month
),
months AS (
    /* 2. List the 12 calendar months so even empty months appear */
    SELECT 1 AS month UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
    SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
    SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
)
/* 3. Pivot the counts into separate year columns */
SELECT
    m.month,
    COALESCE(SUM(CASE WHEN d.year = '2016' THEN d.cnt END), 0) AS "2016",
    COALESCE(SUM(CASE WHEN d.year = '2017' THEN d.cnt END), 0) AS "2017",
    COALESCE(SUM(CASE WHEN d.year = '2018' THEN d.cnt END), 0) AS "2018"
FROM months m
LEFT JOIN delivered_per_month d
       ON d.month = m.month
GROUP BY m.month
ORDER BY m.month;