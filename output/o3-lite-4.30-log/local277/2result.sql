WITH hist AS (
  SELECT
    product_id,
    ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) AS x,
    qty                                                    AS y,
    CASE
      WHEN ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY mth) BETWEEN 7 AND 30
      THEN 2.0 ELSE 1.0
    END                                                    AS w
  FROM monthly_sales
  WHERE product_id IN (4160, 7790)
    AND mth >= '2016-01-01'
    AND mth <  '2019-01-01'
),
sums AS (
  SELECT
    product_id,
    SUM(w)         AS Sw,
    SUM(w*x)       AS Sx,
    SUM(w*y)       AS Sy,
    SUM(w*x*x)     AS Sxx,
    SUM(w*x*y)     AS Sxy
  FROM hist
  GROUP BY product_id
),
params AS (
  SELECT
    product_id,
    (Sw*Sxy - Sx*Sy) * 1.0 / (Sw*Sxx - Sx*Sx)                          AS b,
    (Sy - ((Sw*Sxy - Sx*Sy) * 1.0 / (Sw*Sxx - Sx*Sx)) * Sx) / Sw       AS a
  FROM sums
),
months_2018 AS (
  SELECT 25 AS x UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL
  SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30 UNION ALL
  SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL
  SELECT 34 UNION ALL SELECT 35 UNION ALL SELECT 36
),
pred AS (
  SELECT
    p.product_id,
    p.a + p.b * m.x AS y_hat
  FROM params p
  CROSS JOIN months_2018 m
),
avg_pred AS (
  SELECT
    product_id,
    AVG(y_hat) AS forecasted_annual_sales_2018
  FROM pred
  GROUP BY product_id
)
SELECT
  product_id,
  ROUND(forecasted_annual_sales_2018, 4) AS forecasted_annual_sales_2018
FROM avg_pred
ORDER BY product_id;