WITH annual_revenue AS (
  -- revenue facts for FY 2016 with four‑quarter duration
  SELECT
    qs.submission_number,
    sub.stprba AS state,
    qs.value
  FROM
    `bigquery-public-data.sec_quarterly_financials.quick_summary` qs
  JOIN
    `bigquery-public-data.sec_quarterly_financials.submission`      sub
  USING (submission_number)
  WHERE
    qs.measure_tag IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND qs.number_of_quarters = 4                -- full‑year amount
    AND qs.fiscal_year        = 2016             -- fiscal year 2016
    AND sub.stprba IS NOT NULL
    AND sub.stprba <> ''                          -- keep only valid U.S. states
),
-- keep just one revenue figure per submission (in case multiple tags exist)
dedup AS (
  SELECT
    submission_number,
    state,
    value,
    ROW_NUMBER() OVER (PARTITION BY submission_number ORDER BY value DESC) AS rn
  FROM annual_revenue
),
state_totals AS (
  SELECT
    state,
    SUM(value)/1e9 AS total_revenue_billions      -- convert to billions
  FROM dedup
  WHERE rn = 1
  GROUP BY state
)
SELECT
  state,
  total_revenue_billions
FROM state_totals
ORDER BY total_revenue_billions DESC
LIMIT 1;