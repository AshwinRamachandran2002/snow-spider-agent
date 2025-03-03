SELECT
    CASE strftime('%m', "order_delivered_customer_date")
        WHEN '01' THEN 'Jan'
        WHEN '02' THEN 'Feb'
        WHEN '03' THEN 'Mar'
        WHEN '04' THEN 'Apr'
        WHEN '05' THEN 'May'
        WHEN '06' THEN 'Jun'
        WHEN '07' THEN 'Jul'
        WHEN '08' THEN 'Aug'
        WHEN '09' THEN 'Sep'
        WHEN '10' THEN 'Oct'
        WHEN '11' THEN 'Nov'
        WHEN '12' THEN 'Dec'
    END AS "Month",
    SUM(CASE WHEN strftime('%Y', "order_delivered_customer_date") = '2016' THEN 1 ELSE 0 END) AS "2016",
    SUM(CASE WHEN strftime('%Y', "order_delivered_customer_date") = '2017' THEN 1 ELSE 0 END) AS "2017",
    SUM(CASE WHEN strftime('%Y', "order_delivered_customer_date") = '2018' THEN 1 ELSE 0 END) AS "2018"
FROM
    "olist_orders"
WHERE
    "order_status" = 'delivered'
    AND "order_delivered_customer_date" IS NOT NULL
    AND strftime('%Y', "order_delivered_customer_date") IN ('2016', '2017', '2018')
GROUP BY
    strftime('%m', "order_delivered_customer_date")
ORDER BY
    CAST(strftime('%m', "order_delivered_customer_date") AS INTEGER);