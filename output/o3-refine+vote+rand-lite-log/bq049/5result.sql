WITH pop_21plus AS (          -- 1. 2010 population aged 21 +  (male + female)
  SELECT
    zipcode,
    SUM(population) AS population_21plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age >= 21
    AND gender IN ('male','female')
  GROUP BY zipcode
),
sales_2022 AS (               -- 2. 2022 Bourbon‑whiskey sales in Dubuque County
  SELECT
    REGEXP_EXTRACT(zip_code,r'^(\d{5})') AS zipcode,
    `date`                     AS sale_date,
    sale_dollars
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) = 2022
    AND UPPER(category_name) LIKE '%BOURBON%'
    AND UPPER(county) = 'DUBUQUE'
),
zip_ranking AS (              -- 3. Rank ZIP codes by total 2022 Bourbon sales
  SELECT
    zipcode,
    SUM(sale_dollars) AS total_sales,
    RANK() OVER (ORDER BY SUM(sale_dollars) DESC) AS sales_rank
  FROM sales_2022
  GROUP BY zipcode
),
target_zip AS (               -- 4. Third‑highest ZIP code
  SELECT zipcode
  FROM zip_ranking
  WHERE sales_rank = 3
)
-- 5. Monthly per‑capita Bourbon sales for that ZIP code
SELECT
  FORMAT_DATE('%Y-%m', DATE_TRUNC(s.sale_date, MONTH))          AS year_month,
  ROUND( SUM(s.sale_dollars) / MAX(p.population_21plus), 4 )    AS per_capita_bourbon_sales
FROM sales_2022 AS s
JOIN target_zip AS t ON s.zipcode = t.zipcode
JOIN pop_21plus  AS p ON s.zipcode = p.zipcode
GROUP BY year_month
ORDER BY year_month;