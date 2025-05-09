SELECT 
    month AS delivery_month,
    SUM(CASE WHEN year = 2016 THEN 1 ELSE 0 END) AS orders_2016,
    SUM(CASE WHEN year = 2017 THEN 1 ELSE 0 END) AS orders_2017,
    SUM(CASE WHEN year = 2018 THEN 1 ELSE 0 END) AS orders_2018
FROM (
    SELECT 
        CAST(strftime('%Y', "order_delivered_customer_date") AS INTEGER) AS year,
        CAST(strftime('%m', "order_delivered_customer_date") AS INTEGER) AS month
    FROM "olist_orders"
    WHERE 
        "order_status" = 'delivered'
        AND strftime('%Y', "order_delivered_customer_date") IN ('2016', '2017', '2018')
)
GROUP BY month
ORDER BY month;