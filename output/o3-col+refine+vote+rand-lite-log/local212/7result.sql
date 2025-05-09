/* 5 delivery drivers with the highest average number of daily deliveries */
WITH daily_counts AS (           -- deliveries each driver made per calendar day
    SELECT  dl.driver_id,
            o.order_created_year  AS yr,
            o.order_created_month AS mon,
            o.order_created_day   AS dy,
            COUNT(*)              AS daily_deliveries
    FROM    deliveries  AS dl
    JOIN    orders      AS o
           ON o.order_id = dl.delivery_order_id
    GROUP BY dl.driver_id,
             o.order_created_year,
             o.order_created_month,
             o.order_created_day
),
driver_averages AS (             -- average of those daily counts per driver
    SELECT  driver_id,
            AVG(daily_deliveries) AS avg_daily_deliveries
    FROM    daily_counts
    GROUP BY driver_id
    ORDER BY avg_daily_deliveries DESC
    LIMIT 5                      -- keep only the top-5
)
SELECT  da.driver_id,
        da.avg_daily_deliveries,
        d.driver_modal,
        d.driver_type
FROM    driver_averages AS da
LEFT JOIN drivers        AS d
       ON d.driver_id = da.driver_id
ORDER BY da.avg_daily_deliveries DESC;