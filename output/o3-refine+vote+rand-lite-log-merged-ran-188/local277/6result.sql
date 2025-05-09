WITH sales36 AS (           -- first 36 months (Jan-2016 ‑ Dec-2018)
    SELECT  product_id,
            mth,
            qty,
            ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) AS t
    FROM    monthly_sales
    WHERE   mth BETWEEN '2016-01-01' AND '2018-12-01'
      AND   product_id IN (4160,7790)
),
train AS (                  -- seasonality-adjusted window  (t 7-30)
    SELECT  product_id,
            COUNT(*)                   AS N,
            SUM(t)                     AS sum_x,
            SUM(qty)                   AS sum_y,
            SUM(t*t)                   AS sum_x2,
            SUM(t*qty)                 AS sum_xy
    FROM    sales36
    WHERE   t BETWEEN 7 AND 30
    GROUP BY product_id
),
coeff AS (                  -- weighted/OLS regression  y = a + b·t
    SELECT  product_id,
            ((N*sum_xy) - (sum_x*sum_y))*1.0
            / ((N*sum_x2) - (sum_x*sum_x))                     AS b,   -- slope
            ((sum_y*1.0) -
             (((N*sum_xy) - (sum_x*sum_y))*1.0
              / ((N*sum_x2) - (sum_x*sum_x))) * sum_x) / N     AS a    -- intercept
    FROM    train
),
pred AS (                   -- predict months 25-36  (Jan-2018 ‑ Dec-2018)
    SELECT  s.product_id,
            c.a + c.b*s.t  AS pred_qty
    FROM    sales36 s
    JOIN    coeff  c USING (product_id)
    WHERE   s.t BETWEEN 25 AND 36
),
forecast AS (               -- annual forecast 2018, per product
    SELECT  product_id,
            SUM(pred_qty)  AS forecasted_annual_sales_2018
    FROM    pred
    GROUP BY product_id
)
SELECT  ROUND(AVG(forecasted_annual_sales_2018),4) AS avg_forecasted_annual_sales_2018
FROM    forecast;