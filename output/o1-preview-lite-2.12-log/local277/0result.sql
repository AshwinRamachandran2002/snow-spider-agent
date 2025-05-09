WITH regression_data AS (
  SELECT
    "product_id",
    CAST((julianday("mth") - julianday('2016-01-01')) / 30 + 1 AS INTEGER) AS "time_step",
    "qty" * 1.0 AS "qty"
  FROM "monthly_sales"
  WHERE "product_id" IN (4160, 7790)
    AND "mth" BETWEEN '2016-01-01' AND '2018-12-01'
),
filtered_data AS (
  SELECT *
  FROM regression_data
  WHERE "time_step" BETWEEN 7 AND 30
),
stats AS (
  SELECT
    "product_id",
    COUNT(*) AS n,
    SUM("time_step") AS sum_x,
    SUM("qty") AS sum_y,
    SUM("time_step" * "qty") AS sum_xy,
    SUM("time_step" * "time_step") AS sum_xx
  FROM filtered_data
  GROUP BY "product_id"
),
coefficients AS (
  SELECT
    "product_id",
    (n * sum_xy - sum_x * sum_y) * 1.0 / (n * sum_xx - sum_x * sum_x) AS slope,
    (sum_y - ((n * sum_xy - sum_x * sum_y) * 1.0 / (n * sum_xx - sum_x * sum_x)) * sum_x) / n AS intercept
  FROM stats
),
forecast AS (
  SELECT
    c."product_id",
    ts."time_step",
    (c.slope * ts."time_step" + c.intercept) AS "forecasted_qty"
  FROM coefficients c
  CROSS JOIN (
    SELECT 25 AS "time_step" UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28
    UNION ALL SELECT 29 UNION ALL SELECT 30 UNION ALL SELECT 31 UNION ALL SELECT 32
    UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL SELECT 36
  ) ts
)
SELECT
  "product_id",
  ROUND(SUM("forecasted_qty"), 4) AS "Average Forecasted Annual Sales (2018)"
FROM forecast
GROUP BY "product_id";