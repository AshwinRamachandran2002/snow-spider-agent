WITH months AS (          -- ensure every month (1-12) appears in the final result
    SELECT SEQ4() + 1 AS month_num
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
delivered AS (            -- delivered orders with a valid customer delivery date in 2016-2018
    SELECT delivered_date
    FROM (
        SELECT 
            TO_DATE(TRY_TO_TIMESTAMP("order_delivered_customer_date",
                                      'YYYY-MM-DD HH24:MI:SS')) AS delivered_date
        FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
        WHERE "order_status" = 'delivered'
    )
    WHERE delivered_date IS NOT NULL
      AND YEAR(delivered_date) IN (2016, 2017, 2018)
)
SELECT
    LPAD(m.month_num, 2, '0')                                               AS "MONTH",
    COALESCE(SUM(CASE WHEN YEAR(d.delivered_date) = 2016 THEN 1 ELSE 0 END), 0) AS "2016",
    COALESCE(SUM(CASE WHEN YEAR(d.delivered_date) = 2017 THEN 1 ELSE 0 END), 0) AS "2017",
    COALESCE(SUM(CASE WHEN YEAR(d.delivered_date) = 2018 THEN 1 ELSE 0 END), 0) AS "2018"
FROM months m
LEFT JOIN delivered d
       ON MONTH(d.delivered_date) = m.month_num
GROUP BY m.month_num
ORDER BY m.month_num;