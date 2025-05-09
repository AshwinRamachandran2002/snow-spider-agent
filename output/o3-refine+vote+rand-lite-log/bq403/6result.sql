-- Median revenue vs. median functional expenses, IRS 990 filers
WITH filings AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64) AS filing_year,
    totrevenue,
    totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_*`
  WHERE _TABLE_SUFFIX BETWEEN '2012' AND '2017'          -- limit to 2012‑2017 tables
), medians AS (
  SELECT
    filing_year,
    -- median (50‑th percentile) revenue & expenses
    APPROX_QUANTILES(totrevenue, 100)[OFFSET(50)]    AS median_revenue,
    APPROX_QUANTILES(totfuncexpns, 100)[OFFSET(50)] AS median_expenses
  FROM filings
  WHERE totrevenue    IS NOT NULL
     OR totfuncexpns IS NOT NULL                     -- keep rows that have at least one amount
  GROUP BY filing_year
)
SELECT
  filing_year AS year,
  ABS(median_revenue - median_expenses) AS median_difference
FROM medians
ORDER BY median_difference
LIMIT 3;