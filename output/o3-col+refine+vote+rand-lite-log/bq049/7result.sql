WITH zip_totals AS (
  SELECT
    REGEXP_EXTRACT(`zip_code`, r'(\d{5})') AS zip5,
    SUM(`sale_dollars`)                    AS bourbon_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `county` = 'DUBUQUE'
    AND EXTRACT(YEAR FROM `date`) = 2022
    AND LOWER(`category_name`) LIKE '%bourbon%'
  GROUP BY zip5
),
ranked_zips AS (
  SELECT
    zip5,
    bourbon_sales,
    DENSE_RANK() OVER (ORDER BY bourbon_sales DESC) AS rnk
  FROM zip_totals
),
selected_zip AS (
  SELECT zip5
  FROM ranked_zips
  WHERE rnk = 3
),
population_21_plus AS (
  SELECT
    SUM(`population`) AS pop_21_plus
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE `zipcode` IN (SELECT zip5 FROM selected_zip)
    AND (`gender` IS NULL OR `gender` = '')
    AND `minimum_age` >= 21
),
monthly_sales AS (
  SELECT
    DATE_TRUNC(`date`, MONTH) AS sales_month,
    SUM(`sale_dollars`)       AS monthly_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE `county` = 'DUBUQUE'
    AND EXTRACT(YEAR FROM `date`) = 2022
    AND LOWER(`category_name`) LIKE '%bourbon%'
    AND REGEXP_EXTRACT(`zip_code`, r'(\d{5})') IN (SELECT zip5 FROM selected_zip)
  GROUP BY sales_month
)
SELECT
  m.sales_month,
  ROUND(m.monthly_sales / p.pop_21_plus, 4) AS per_capita_sales_dollars
FROM monthly_sales AS m
CROSS JOIN population_21_plus AS p
ORDER BY m.sales_month;