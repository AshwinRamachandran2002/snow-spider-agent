WITH revenue_by_state AS (
  SELECT
    s.stprba AS state,
    SUM(qs.value) / 1e9 AS total_revenue_billion_usd
  FROM `bigquery-public-data.sec_quarterly_financials.quick_summary` qs
  JOIN `bigquery-public-data.sec_quarterly_financials.submission`      s
    ON qs.submission_number = s.submission_number
  WHERE qs.fiscal_year        = 2016
    AND qs.number_of_quarters = 4
    AND LOWER(qs.measure_tag) IN ('revenues',
                                  'salesrevenuenet',
                                  'salesrevenuegoodsnet')
    AND s.stprba IS NOT NULL
    AND s.stprba != ''
  GROUP BY state
)
SELECT
  state AS highest_revenue_state,
  ROUND(total_revenue_billion_usd, 2) AS total_revenue_billion_usd
FROM revenue_by_state
ORDER BY total_revenue_billion_usd DESC
LIMIT 1;