WITH iowa_bourbon_2022 AS (
  SELECT
    -- clean 5‑digit ZIP code (keeps any leading zeros)
    LPAD(SPLIT(zip_code, '.')[OFFSET(0)], 5, '0') AS zipcode5,
    LOWER(county) AS county_lc,
    date,
    sale_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
    date BETWEEN '2022-01-01' AND '2022-12-31'
    AND LOWER(category_name) LIKE '%bourbon%'          -- Bourbon whiskey only
    AND sale_dollars > 0                               -- ignore returns / corrections
    AND LOWER(county) = 'dubuque'                      -- Dubuque County
),

zip_totals AS (                                            -- total 2022 sales by ZIP
  SELECT
    zipcode5,
    SUM(sale_dollars) AS total_sales
  FROM iowa_bourbon_2022
  GROUP BY zipcode5
),

third_zip AS (                                             -- ZIP ranked 3rd in sales
  SELECT zipcode5
  FROM (
    SELECT
      zipcode5,
      total_sales,
      ROW_NUMBER() OVER (ORDER BY total_sales DESC, zipcode5) AS rn
    FROM zip_totals
  )
  WHERE rn = 3
),

monthly_sales AS (                                         -- monthly sales in that ZIP
  SELECT
    FORMAT_DATE('%Y-%m', date) AS month,
    SUM(sale_dollars)       AS monthly_sales,
    z.zipcode5
  FROM iowa_bourbon_2022 AS s
  JOIN third_zip        AS z
  ON  s.zipcode5 = z.zipcode5
  GROUP BY month, z.zipcode5
),

population_21_plus AS (                                    -- pop ≥21 in that ZIP
  SELECT
    zipcode AS zipcode5,
    SUM(population) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age >= 21                                 -- only age 21+
  GROUP BY zipcode
)

SELECT
  m.zipcode5               AS zipcode,
  m.month,
  ROUND(m.monthly_sales / p.pop_21_plus, 4) AS per_capita_sales
FROM monthly_sales      AS m
JOIN population_21_plus AS p
ON  m.zipcode5 = p.zipcode5
ORDER BY m.month;