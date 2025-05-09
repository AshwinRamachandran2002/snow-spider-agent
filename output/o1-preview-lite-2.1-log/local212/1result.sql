SELECT
    driver_id,
    ROUND(AVG(daily_deliveries), 4) AS average_daily_deliveries
FROM
    (
        SELECT
            d.driver_id,
            printf('%04d-%02d-%02d', o.order_created_year, o.order_created_month, o.order_created_day) AS delivery_date,
            COUNT(*) AS daily_deliveries
        FROM
            deliveries d
        JOIN
            orders o ON d.delivery_order_id = o.order_id
        WHERE
            d.driver_id IS NOT NULL
            AND LOWER(d.delivery_status) = 'delivered'
        GROUP BY
            d.driver_id,
            delivery_date
    ) dd
GROUP BY
    driver_id
ORDER BY
    average_daily_deliveries DESC
LIMIT 5;