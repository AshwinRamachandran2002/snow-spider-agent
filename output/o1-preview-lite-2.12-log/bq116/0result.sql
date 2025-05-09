SELECT
  s.stprba AS State,
  ROUND(SUM(n.value)/1e9, 4) AS total_annual_revenue_billions_usd
FROM
  `bigquery-public-data.sec_quarterly_financials.numbers` n
JOIN
  `bigquery-public-data.sec_quarterly_financials.submission` s
ON
  n.submission_number = s.submission_number
WHERE
  n.number_of_quarters = 4
  AND n.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
  AND n.units = 'USD'
  AND s.fiscal_year = 2016
  AND s.fiscal_period_focus = 'FY'
  AND s.countryba = 'US'
  AND s.stprba IS NOT NULL
  AND s.stprba != ''
GROUP BY
  s.stprba
ORDER BY
  SUM(n.value) DESC
LIMIT 1