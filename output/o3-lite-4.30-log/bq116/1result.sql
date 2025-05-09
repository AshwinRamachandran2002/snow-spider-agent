SELECT
  s.stprba,
  ROUND(SUM(n.value) / 1e9, 4) AS total_annual_revenue_billions_usd
FROM `bigquery-public-data.sec_quarterly_financials.numbers`    AS n
JOIN `bigquery-public-data.sec_quarterly_financials.submission` AS s
  ON n.submission_number = s.submission_number
WHERE s.fiscal_year = 2016
  AND n.number_of_quarters = 4
  AND n.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
  AND n.units = 'USD'
  AND n.num_dimensions = 0
  AND (n.coregistrant IS NULL OR n.coregistrant = '')
  AND s.stprba IS NOT NULL
  AND s.stprba <> ''
GROUP BY s.stprba
ORDER BY total_annual_revenue_billions_usd DESC, s.stprba
LIMIT 1;