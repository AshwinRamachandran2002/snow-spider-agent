/*  Monthly per‑capita Bourbon‑whiskey sales during 2022 in Dubuque County
    using the ZIP code that ranks 3rd in total Bourbon sales (or the lowest
    ranking ZIP available if <3 exist) and population aged 21 +.            */

-- 1) All 2022 Bourbon‑whiskey sales in Dubuque County, aggregated monthly
WITH bourbon_2022 AS (
  SELECT
    REGEXP_EXTRACT(CAST(zip_code AS STRING), r'\d{5}')           AS zipcode,   -- 5‑digit ZIP
    EXTRACT(MONTH FROM date)                                     AS month,
    SUM(sale_dollars)                                            AS month_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
        UPPER(TRIM(county)) = 'DUBUQUE'                          -- Dubuque County
    AND EXTRACT(YEAR FROM date) = 2022                           -- calendar year 2022
    AND REGEXP_CONTAINS(UPPER(category_name), r'BOURBON')        -- Bourbon products
  GROUP BY zipcode, month
),

-- 2) Rank ZIP codes by total 2022 Bourbon sales (highest → lowest)
zip_totals AS (
  SELECT
    zipcode,
    SUM(month_sales)                        AS total_sales,
    RANK() OVER (ORDER BY SUM(month_sales) DESC) AS rk
  FROM bourbon_2022
  GROUP BY zipcode
),

-- 3) Choose the 3rd‑highest ZIP; if fewer than 3 ZIPs exist, pick the lowest‑ranked available
chosen_zip AS (
  SELECT
    COALESCE(
      (SELECT zipcode FROM zip_totals WHERE rk = 3),
      (SELECT zipcode FROM zip_totals ORDER BY rk DESC LIMIT 1)
    ) AS zipcode
),

-- 4) Monthly sales for the chosen ZIP
monthly_sales AS (
  SELECT
    month,
    SUM(month_sales) AS total_month_sales
  FROM bourbon_2022
  WHERE zipcode = (SELECT zipcode FROM chosen_zip)
  GROUP BY month
),

-- 5) 2010 Census population aged 21 + for that ZIP
pop_21_plus AS (
  SELECT
    LPAD(zipcode, 5, '0') AS zipcode,                   -- ensure 5‑digit format
    SUM(population) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE
        gender IS NULL                                   -- overall rows
    AND minimum_age IS NOT NULL
    AND minimum_age >= 21                                -- age 21 +
    AND LPAD(zipcode, 5, '0') = (SELECT zipcode FROM chosen_zip)
  GROUP BY zipcode
)

-- 6) Final per‑capita figures
SELECT
  m.month                                  AS month,
  ROUND(m.total_month_sales / p.pop_21_plus, 4) AS per_capita_sales
FROM monthly_sales AS m
LEFT JOIN pop_21_plus AS p
ON TRUE                                      -- single‑row join
ORDER BY m.month;