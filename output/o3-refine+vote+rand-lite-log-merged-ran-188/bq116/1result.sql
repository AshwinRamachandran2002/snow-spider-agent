SELECT
  s.stprba AS state,
  SUM(q.value)/1e9 AS total_revenue_billions
FROM `bigquery-public-data.sec_quarterly_financials.quick_summary` AS q
JOIN `bigquery-public-data.sec_quarterly_financials.submission` AS s
  ON q.submission_number = s.submission_number
WHERE q.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
  AND q.number_of_quarters = 4        -- full-year values
  AND s.fiscal_year = 2016            -- fiscal year 2016
  AND s.stprba IS NOT NULL            -- exclude missing states
  AND TRIM(s.stprba) <> ''            -- exclude empty strings
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;