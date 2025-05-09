WITH base AS (
    SELECT  product_id,
            mth,
            qty,
            ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) AS t
    FROM    monthly_sales
    WHERE   product_id IN (4160, 7790)
      AND   mth >= '2016-01-01'
    ORDER BY product_id, mth
    LIMIT   72                                  -- first 36 months for each product
),
season AS (                                     -- seasonality window t = 7 … 30
    SELECT * 
    FROM   base
    WHERE  t BETWEEN 7 AND 30
),
params AS (                                     -- regression coefficients
    SELECT  product_id,
            (COUNT(*)*SUM(t*qty) - SUM(t)*SUM(qty)) /
            (COUNT(*)*SUM(t*t)  - SUM(t)*SUM(t))                 AS slope,
            (SUM(qty) - (
                (COUNT(*)*SUM(t*qty) - SUM(t)*SUM(qty)) /
                (COUNT(*)*SUM(t*t)  - SUM(t)*SUM(t))
            ) * SUM(t)) / COUNT(*)                               AS intercept
    FROM    season
    GROUP BY product_id
),
forecast AS (                                   -- predict t = 25 … 36  (year 2018)
    SELECT  b.product_id,
            p.intercept + p.slope*b.t           AS predicted_qty
    FROM    base b
    JOIN    params p USING (product_id)
    WHERE   b.t BETWEEN 25 AND 36
)
SELECT  product_id,
        ROUND(AVG(predicted_qty), 2) AS avg_forecast_2018
FROM    forecast
GROUP BY product_id;