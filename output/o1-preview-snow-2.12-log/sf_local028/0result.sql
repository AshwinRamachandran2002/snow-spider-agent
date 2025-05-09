WITH orders AS (
    SELECT
        EXTRACT(MONTH FROM TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) AS month_num,
        EXTRACT(YEAR FROM TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS')) AS year_num
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
    WHERE "order_status" = 'delivered'
      AND TRY_TO_TIMESTAMP("order_delivered_customer_date", 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL
),
months AS (
    SELECT 1 AS month_num, 'January' AS month_name UNION ALL
    SELECT 2, 'February' UNION ALL
    SELECT 3, 'March' UNION ALL
    SELECT 4, 'April' UNION ALL
    SELECT 5, 'May' UNION ALL
    SELECT 6, 'June' UNION ALL
    SELECT 7, 'July' UNION ALL
    SELECT 8, 'August' UNION ALL
    SELECT 9, 'September' UNION ALL
    SELECT 10, 'October' UNION ALL
    SELECT 11, 'November' UNION ALL
    SELECT 12, 'December'
)
SELECT
    m.month_name AS "Month",
    COALESCE(SUM(CASE WHEN o.year_num = 2016 THEN 1 ELSE 0 END), 0) AS "2016",
    COALESCE(SUM(CASE WHEN o.year_num = 2017 THEN 1 ELSE 0 END), 0) AS "2017",
    COALESCE(SUM(CASE WHEN o.year_num = 2018 THEN 1 ELSE 0 END), 0) AS "2018"
FROM months m
LEFT JOIN orders o ON m.month_num = o.month_num
GROUP BY m.month_num, m.month_name
ORDER BY m.month_num;