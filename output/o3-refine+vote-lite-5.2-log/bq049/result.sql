/*  Monthly per‑capita Bourbon‑whiskey sales in 2022 for Dubuque County.
    – “Bourbon Whiskey” rows are identified by the official category name
      used in the data set:  ‘STRAIGHT BOURBON WHISKIES’.
    – We pick the ZIP code that ranks 3rd in total 2022 Bourbon sales
      (or, if there are fewer than 3 ZIP codes with sales, the one that
      ranks last).
    – Per‑capita figures use the 2010 Census population aged 21+.          */

WITH bourbon_2022 AS (                       -- 1.  2022 Bourbon sales, Dubuque Co.
  SELECT
    LPAD(SUBSTR(CAST(zip_code AS STRING), 1, 5), 5, '0') AS zip5,
    date,
    sale_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM date) = 2022
    AND category_name = 'STRAIGHT BOURBON WHISKIES'      -- Bourbon category
    AND TRIM(UPPER(county)) = 'DUBUQUE'                  -- Dubuque County
),

ranked AS (                               -- 2.  Total Bourbon sales by ZIP
  SELECT
    zip5,
    SUM(sale_dollars) AS total_sales
  FROM bourbon_2022
  GROUP BY zip5
),

third_zip AS (                            -- 3.  ZIP that is 3rd (or last if <3)
  SELECT zip5
  FROM (
    SELECT
      zip5,
      total_sales,
      ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
      COUNT(*) OVER ()                               AS cnt
    FROM ranked
  )
  WHERE (cnt >= 3 AND rn = 3) OR (cnt < 3 AND rn = cnt)
  LIMIT 1
),

monthly_totals AS (                       -- 4.  Monthly $ sales for that ZIP
  SELECT
    FORMAT_DATE('%Y-%m', date) AS month,
    SUM(sale_dollars)         AS sales_dollars,
    zip5
  FROM bourbon_2022
  WHERE zip5 IN (SELECT zip5 FROM third_zip)
  GROUP BY month, zip5
),

pop_21_plus AS (                          -- 5.  2010 population aged 21+ by ZIP
  SELECT
    LPAD(zipcode, 5, '0') AS zip5,
    SUM(population)       AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE gender IS NULL        -- overall population (not sex‑specific)
    AND minimum_age >= 21     -- age 21 and over
  GROUP BY zip5
)

-- 6.  Final per‑capita monthly results
SELECT
  m.month,
  ROUND(m.sales_dollars / NULLIF(p.pop_21_plus, 0), 4) AS per_capita_sales_usd
FROM monthly_totals AS m
LEFT JOIN pop_21_plus AS p USING (zip5)
ORDER BY m.month;