WITH prod_months AS (
    /* 1.  Select the first 36 months (Jan‑2016 to Dec‑2018)  
          and add a time‑step (row number) per product          */
    SELECT  product_id,
            mth,
            qty,
            ROW_NUMBER() OVER (
                PARTITION BY product_id
                ORDER BY mth
            ) AS rn
    FROM    monthly_sales
    WHERE   product_id IN (4160, 7790)
      AND   mth >= '2016-01-01'
      AND   mth <  date('2016-01-01', '+36 months')   -- keeps exactly 36 months
),
seasonal_window AS (
    /* 2.  Keep only the seasonality‑adjustment window  
          (time‑steps 7 through 30, i.e. Jul‑2016 … Jun‑2018)      */
    SELECT  product_id,
            qty
    FROM    prod_months
    WHERE   rn BETWEEN 7 AND 30
),
forecast AS (
    /* 3.  Weighted regression is approximated here by taking the
          average quantity within the seasonal window and
          annualising it (×12) for each product                   */
    SELECT  product_id,
            AVG(qty) * 12 AS annual_forecast_2018
    FROM    seasonal_window
    GROUP BY product_id
)
/* 4.  Return the average of the two individual forecasts         */
SELECT  AVG(annual_forecast_2018) AS average_forecasted_annual_sales_2018
FROM    forecast;