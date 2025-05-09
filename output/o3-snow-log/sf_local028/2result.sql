WITH parsed AS (
    SELECT
        "order_status",
        TRY_TO_TIMESTAMP_NTZ("order_delivered_customer_date") AS delivered_ts
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS
),
delivered_orders AS (
    SELECT
        MONTH(delivered_ts) AS mth,
        YEAR(delivered_ts)  AS yr
    FROM parsed
    WHERE "order_status" = 'delivered'
      AND delivered_ts IS NOT NULL
      AND YEAR(delivered_ts) BETWEEN 2016 AND 2018
)
SELECT
    LPAD(TO_CHAR(mth), 2, '0')                               AS "month",
    SUM(CASE WHEN yr = 2016 THEN 1 ELSE 0 END)               AS "2016",
    SUM(CASE WHEN yr = 2017 THEN 1 ELSE 0 END)               AS "2017",
    SUM(CASE WHEN yr = 2018 THEN 1 ELSE 0 END)               AS "2018"
FROM delivered_orders
GROUP BY mth
ORDER BY mth;