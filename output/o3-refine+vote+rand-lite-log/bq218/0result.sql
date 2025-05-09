WITH yearly_sales AS (
  SELECT
    item_number,
    item_description,
    EXTRACT(YEAR FROM `date`) AS sales_year,
    SUM(sale_dollars) AS total_revenue
  FROM
    `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE
    sale_dollars IS NOT NULL
  GROUP BY
    item_number,
    item_description,
    sales_year
),
pivot AS (
  SELECT
    item_number,
    ANY_VALUE(item_description) AS item_description,
    SUM(CASE WHEN sales_year = 2022 THEN total_revenue END) AS rev_2022,
    SUM(CASE WHEN sales_year = 2023 THEN total_revenue END) AS rev_2023
  FROM
    yearly_sales
  WHERE
    sales_year IN (2022, 2023)
  GROUP BY
    item_number
),
growth AS (
  SELECT
    item_number,
    item_description,
    rev_2022,
    rev_2023,
    ROUND(SAFE_DIVIDE(rev_2023 - rev_2022, rev_2022) * 100, 4) AS growth_pct
  FROM
    pivot
  WHERE
    rev_2022 > 0          -- ensure valid percentage calculation
    AND rev_2023 IS NOT NULL
)
SELECT
  item_number,
  item_description,
  rev_2022,
  rev_2023,
  growth_pct
FROM
  growth
ORDER BY
  growth_pct DESC,
  item_number
LIMIT 5;