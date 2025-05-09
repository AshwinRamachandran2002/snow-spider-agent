WITH sales_2022 AS (               -- 2022 Bourbon‐whiskey sales in Dubuque County
  SELECT
    SUBSTR(CAST(`zip_code` AS STRING), 1, 5) AS zip_code,   -- keep first 5 digits
    `date`,
    `sale_dollars`
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE county = 'DUBUQUE'
    AND EXTRACT(YEAR FROM `date`) = 2022
    AND LOWER(`category_name`) LIKE '%bourbon%'
),
third_zip AS (                     -- ZIP code that ranks 3rd in total 2022 sales
  SELECT zip_code
  FROM (
    SELECT
      zip_code,
      SUM(sale_dollars)                               AS total_sales,
      DENSE_RANK() OVER (ORDER BY SUM(sale_dollars) DESC) AS rnk
    FROM sales_2022
    GROUP BY zip_code
  )
  WHERE rnk = 3
),
pop21 AS (                         -- population aged 21+ for every ZIP
  SELECT
    `zipcode`                        AS zip_code,
    SUM(`population`)               AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE `minimum_age` >= 21
    AND LOWER(`gender`) IN ('male', 'female')         -- avoid double-counting totals
  GROUP BY zip_code
)
SELECT
  FORMAT_DATE('%Y-%m', s.date)                  AS year_month,
  ROUND(SUM(s.sale_dollars) / p.pop_21_plus, 4) AS per_capita_sales_dollars
FROM sales_2022 AS s
JOIN third_zip t ON s.zip_code = t.zip_code
JOIN pop21     p ON p.zip_code = t.zip_code
GROUP BY year_month, p.pop_21_plus
ORDER BY year_month;