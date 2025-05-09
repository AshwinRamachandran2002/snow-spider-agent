SELECT
  s.stprba AS state,
  SUM(n.value) / 1e9 AS total_revenue_billions
FROM `bigquery-public-data.sec_quarterly_financials.numbers`     AS n
JOIN `bigquery-public-data.sec_quarterly_financials.submission`  AS s
  ON n.submission_number = s.submission_number
WHERE s.fiscal_year = 2016
  AND s.countryba = 'US'
  AND s.stprba IS NOT NULL
  AND s.stprba <> ''
  AND n.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
  AND n.number_of_quarters = 4
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;