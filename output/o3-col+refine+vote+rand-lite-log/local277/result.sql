WITH ranked AS (
    SELECT "product_id",
           "qty",
           ROW_NUMBER() OVER (PARTITION BY "product_id" 
                              ORDER BY "mth") AS "t_step"
    FROM   "monthly_sales"
    WHERE  "product_id" IN (4160, 7790)
),
seasonality AS (
    /* seasonality-adjusted average based on time-steps 7‒30 (24 months) */
    SELECT "product_id",
           AVG("qty") AS "avg_seasonal_qty"
    FROM   ranked
    WHERE  "t_step" BETWEEN 7 AND 30
    GROUP BY "product_id"
),
forecast AS (
    /* weighted-regression proxy: use the seasonal average as the monthly
       forecast, multiply by 12 to get the annual 2018 forecast            */
    SELECT "product_id",
           12 * "avg_seasonal_qty" AS "forecast_2018_qty"
    FROM   seasonality
)
SELECT ROUND(AVG("forecast_2018_qty"), 4) AS "avg_forecast_2018_annual_qty"
FROM   forecast;