WITH long_term_debt_by_country AS (
  SELECT
    country_code,
    SUM(value) AS total_long_term_debt_usd
  FROM
    `bigquery-public-data.world_bank_wdi.indicators_data`
  WHERE
    indicator_code = 'DT.DOD.DLXF.CD'      -- External debt stocks, long‑term (current US$)
  GROUP BY
    country_code
),
eligible_countries AS (
  SELECT
    country_code,
    short_name AS country,
    region
  FROM
    `bigquery-public-data.world_bank_wdi.country_summary`
  WHERE
    region IS NOT NULL                     -- exclude aggregates with unspecified region
)

SELECT
  ec.country,
  ltd.total_long_term_debt_usd
FROM
  long_term_debt_by_country AS ltd
JOIN
  eligible_countries AS ec
USING (country_code)
WHERE
  ltd.total_long_term_debt_usd IS NOT NULL
ORDER BY
  ltd.total_long_term_debt_usd DESC,
  ec.country ASC
LIMIT 10;