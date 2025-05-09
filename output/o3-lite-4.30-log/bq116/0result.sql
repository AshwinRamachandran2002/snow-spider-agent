SELECT
  s.stprba,
  ROUND(SUM(qs.value)/1e9, 4) AS total_annual_revenue_billions_usd
FROM `bigquery-public-data.sec_quarterly_financials.quick_summary` qs
JOIN `bigquery-public-data.sec_quarterly_financials.submission` s
  USING (submission_number)
WHERE qs.fiscal_year = 2016
  AND qs.number_of_quarters = 4
  AND qs.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
  AND qs.units = 'USD'
  AND s.stprba IS NOT NULL
  AND s.stprba <> ''
GROUP BY s.stprba
ORDER BY total_annual_revenue_billions_usd DESC
LIMIT 1;