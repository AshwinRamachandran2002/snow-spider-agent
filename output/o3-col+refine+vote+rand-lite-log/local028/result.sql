-- Report: Delivered orders per month, with separate columns for 2016, 2017, and 2018
SELECT
    SUBSTR("order_purchase_timestamp", 6, 2) AS "month",
    SUM(CASE WHEN SUBSTR("order_purchase_timestamp", 1, 4) = '2016' THEN 1 ELSE 0 END) AS "2016",
    SUM(CASE WHEN SUBSTR("order_purchase_timestamp", 1, 4) = '2017' THEN 1 ELSE 0 END) AS "2017",
    SUM(CASE WHEN SUBSTR("order_purchase_timestamp", 1, 4) = '2018' THEN 1 ELSE 0 END) AS "2018"
FROM
    "olist_orders"
WHERE
    "order_status" = 'delivered'
    AND SUBSTR("order_purchase_timestamp", 1, 4) IN ('2016', '2017', '2018')
GROUP BY
    "month"
ORDER BY
    "month";