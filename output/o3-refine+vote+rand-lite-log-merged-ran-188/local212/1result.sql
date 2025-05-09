WITH delivery_dates AS (
    SELECT
        d.driver_id,
        printf('%04d-%02d-%02d',
               o.order_created_year,
               o.order_created_month,
               o.order_created_day
        ) AS delivery_date
    FROM deliveries AS d
    JOIN orders AS o
      ON o.order_id = d.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'
          AND o.order_created_year  IS NOT NULL
          AND o.order_created_month IS NOT NULL
          AND o.order_created_day   IS NOT NULL
),
driver_daily AS (
    SELECT
        driver_id,
        delivery_date,
        COUNT(*) AS deliveries_in_day
    FROM delivery_dates
    GROUP BY driver_id, delivery_date
),
driver_avg AS (
    SELECT
        driver_id,
        AVG(deliveries_in_day) AS avg_daily_deliveries
    FROM driver_daily
    GROUP BY driver_id
)
SELECT
    driver_id,
    ROUND(avg_daily_deliveries, 4) AS avg_daily_deliveries
FROM driver_avg
ORDER BY avg_daily_deliveries DESC, driver_id
LIMIT 5;