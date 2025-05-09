WITH daily_deliveries AS (
    /* 1️⃣  Count how many deliveries each driver completes per calendar day */
    SELECT  d."driver_id",
            o."order_created_year",
            o."order_created_month",
            o."order_created_day",
            COUNT(*) AS daily_deliveries
    FROM    "deliveries" AS d
    JOIN    "orders"     AS o
            ON o."order_id" = d."delivery_order_id"
    WHERE   d."driver_id" IS NOT NULL                 -- ignore unidentified drivers
    GROUP BY d."driver_id",
             o."order_created_year",
             o."order_created_month",
             o."order_created_day"
),
avg_per_driver AS (
    /* 2️⃣  Compute each driver’s average number of daily deliveries */
    SELECT  driver_id,
            ROUND(AVG(daily_deliveries), 4) AS avg_daily_deliveries
    FROM    daily_deliveries
    GROUP BY driver_id
),
top_5 AS (
    /* 3️⃣  Keep only the five highest averages */
    SELECT *
    FROM   avg_per_driver
    ORDER BY avg_daily_deliveries DESC
    LIMIT 5
)
/* 4️⃣  Bring in driver attributes for the final answer */
SELECT  t.driver_id,
        dv.driver_modal,
        dv.driver_type,
        t.avg_daily_deliveries
FROM    top_5          AS t
LEFT JOIN "drivers" AS dv ON dv."driver_id" = t.driver_id
ORDER BY t.avg_daily_deliveries DESC;