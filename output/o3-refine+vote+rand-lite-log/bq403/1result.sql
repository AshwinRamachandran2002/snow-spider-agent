WITH data AS (
  -- pull 2012‑2017 Form‑990 filings; keep total revenue & functional expenses
  SELECT
    2000 + CAST(_TABLE_SUFFIX AS INT64)      AS filing_year,      -- 20 + 12 → 2012
    SAFE_CAST(totrevenue    AS FLOAT64)      AS revenue,
    SAFE_CAST(totfuncexpns  AS FLOAT64)      AS expenses
  FROM `bigquery-public-data.irs_990.irs_990_20*`
  WHERE _TABLE_SUFFIX IN ('12','13','14','15','16','17')           -- years 2012‑2017
        AND totrevenue   IS NOT NULL
        AND totfuncexpns IS NOT NULL
),
medians AS (
  -- median revenue & expenses for each year
  SELECT
    filing_year,
    APPROX_QUANTILES(revenue ,2)[OFFSET(1)]  AS median_revenue,
    APPROX_QUANTILES(expenses,2)[OFFSET(1)]  AS median_expenses
  FROM data
  GROUP BY filing_year
),
diffs AS (
  -- absolute difference between medians
  SELECT
    filing_year,
    ABS(median_revenue - median_expenses) AS median_diff
  FROM medians
)
-- three years with smallest differences
SELECT
  filing_year AS year,
  median_diff AS difference
FROM diffs
ORDER BY median_diff, filing_year
LIMIT 3;