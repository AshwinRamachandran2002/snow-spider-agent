WITH RECURSIVE months(month_num) AS (
    SELECT 1
    UNION ALL
    SELECT month_num + 1 FROM months WHERE month_num < 12
),
delivered AS (
    SELECT
        CAST(strftime('%m', "order_delivered_customer_date") AS INTEGER) AS month_num,
        strftime('%Y', "order_delivered_customer_date")              AS year_delivered
    FROM "olist_orders"
    WHERE "order_status" = 'delivered'
      AND "order_delivered_customer_date" IS NOT NULL
      AND strftime('%Y', "order_delivered_customer_date") IN ('2016', '2017', '2018')
)
SELECT
    m.month_num                                            AS month,
    COALESCE(SUM(CASE WHEN d.year_delivered = '2016' THEN 1 END), 0) AS "2016",
    COALESCE(SUM(CASE WHEN d.year_delivered = '2017' THEN 1 END), 0) AS "2017",
    COALESCE(SUM(CASE WHEN d.year_delivered = '2018' THEN 1 END), 0) AS "2018"
FROM months AS m
LEFT JOIN delivered AS d
       ON m.month_num = d.month_num
GROUP BY m.month_num
ORDER BY m.month_num;