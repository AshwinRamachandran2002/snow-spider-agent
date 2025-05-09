WITH cleaned_sales AS (
  -- 1. 2022 Bourbon‑whiskey sales made in Dubuque County
  SELECT
    DATE_TRUNC(`date`, MONTH)                                                AS month,
    LPAD(REGEXP_EXTRACT(CAST(zip_code AS STRING), r'\d+'), 5, '0')           AS zipcode,
    sale_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `date` >= '2022-01-01' AND `date` < '2023-01-01'
    AND UPPER(county) = 'DUBUQUE'
    AND IFNULL(LOWER(category_name), '') LIKE '%bourbon%'                    -- Bourbon rows
),
zip_rank AS (
  -- 2. Rank ZIP codes by total 2022 Bourbon sales
  SELECT
    zipcode,
    SUM(sale_dollars)                                   AS total_sales,
    RANK() OVER (ORDER BY SUM(sale_dollars) DESC)       AS rk
  FROM cleaned_sales
  GROUP BY zipcode
),
third_zip AS (
  -- 3. ZIP code that ranks third
  SELECT zipcode
  FROM zip_rank
  WHERE rk = 3
),
monthly_sales AS (
  -- 4. Monthly sales for that ZIP
  SELECT
    DATE_TRUNC(month, MONTH) AS month,
    SUM(sale_dollars)        AS monthly_sales
  FROM cleaned_sales
  WHERE zipcode IN (SELECT zipcode FROM third_zip)
  GROUP BY month
),
pop_21 AS (
  -- 5. 21‑and‑older population from the 2010 Census
  SELECT
    LPAD(zipcode, 5, '0')      AS zipcode,
    SUM(population)            AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE gender IS NULL
    AND minimum_age IS NOT NULL
    AND minimum_age >= 21
  GROUP BY zipcode
),
final AS (
  -- 6. Per‑capita monthly sales
  SELECT
    m.month,
    SAFE_DIVIDE(m.monthly_sales, p.pop_21_plus) AS per_capita_sales
  FROM monthly_sales m
  CROSS JOIN third_zip z
  LEFT JOIN pop_21 p
  ON p.zipcode = z.zipcode
)
SELECT
  FORMAT_DATE('%Y-%m', month) AS month,
  ROUND(per_capita_sales, 4)  AS per_capita_sales
FROM final
ORDER BY month;