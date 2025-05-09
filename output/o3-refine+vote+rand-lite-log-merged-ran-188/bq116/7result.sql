-- Which U.S. state had the highest total FY-2016 revenue (in billions)?
WITH revenue_by_state AS (
  SELECT
    s.stprba AS state,
    SUM(qs.value) / 1e9 AS total_revenue_billion          -- convert to billions
  FROM `bigquery-public-data.sec_quarterly_financials.quick_summary` qs
  JOIN `bigquery-public-data.sec_quarterly_financials.submission`      s
    ON qs.submission_number = s.submission_number
  WHERE qs.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
    AND qs.fiscal_year        = 2016        -- fiscal year 2016
    AND qs.number_of_quarters = 4           -- full-year data (4 quarters)
    AND s.stprba IS NOT NULL                -- state must be present
    AND TRIM(s.stprba) <> ''                -- …and not blank
  GROUP BY state
)

SELECT
  state,
  total_revenue_billion
FROM revenue_by_state
ORDER BY total_revenue_billion DESC
LIMIT 1;