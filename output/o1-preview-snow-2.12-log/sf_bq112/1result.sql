WITH cpi_data AS (
  SELECT
    "year",
    AVG("value") AS "average_cpi"
  FROM
    BLS.BLS."CPI_U"
  WHERE
    "year" IN (1998, 2017)
    AND "area_name" = 'Pittsburgh, PA'
    AND "item_name" = 'All items'
  GROUP BY
    "year"
),
cpi_pivot AS (
  SELECT
    MAX(CASE WHEN "year" = 1998 THEN "average_cpi" END) AS "cpi_1998",
    MAX(CASE WHEN "year" = 2017 THEN "average_cpi" END) AS "cpi_2017"
  FROM
    cpi_data
),
wage_data AS (
  SELECT
    1998 AS "year",
    ("avg_wkly_wage_10_total_all_industries" * 52) AS "annual_wage"
  FROM
    BLS.BLS_QCEW."_1998_Q4"
  WHERE
    "area_fips" = '42003'
  UNION ALL
  SELECT
    2017 AS "year",
    ("avg_wkly_wage_10_total_all_industries" * 52) AS "annual_wage"
  FROM
    BLS.BLS_QCEW."_2017_Q4"
  WHERE
    "area_fips" = '42003'
),
wage_pivot AS (
  SELECT
    MAX(CASE WHEN "year" = 1998 THEN "annual_wage" END) AS "wage_1998",
    MAX(CASE WHEN "year" = 2017 THEN "annual_wage" END) AS "wage_2017"
  FROM
    wage_data
)
SELECT
  ROUND((("wage_2017" - "wage_1998") / "wage_1998") * 100, 2) AS "Wage_growth_rate",
  ROUND((("cpi_2017" - "cpi_1998") / "cpi_1998") * 100, 2) AS "Inflation_rate"
FROM
  wage_pivot,
  cpi_pivot;