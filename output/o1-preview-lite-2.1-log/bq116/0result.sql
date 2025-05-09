SELECT
  s.stprba AS State,
  ROUND(MAX(n.value) / 1e9, 4) AS Highest_Annual_Revenue_Billions
FROM
  `bigquery-public-data.sec_quarterly_financials.numbers` AS n
JOIN
  `bigquery-public-data.sec_quarterly_financials.submission` AS s
ON
  n.submission_number = s.submission_number
WHERE
  n.measure_tag = 'Revenues'
  AND s.countryba = 'US'
  AND s.fiscal_year = 2016
  AND s.fiscal_period_focus = 'FY'
  AND n.number_of_quarters = 4
  AND n.units = 'USD'
  AND n.value > 0
GROUP BY State
ORDER BY Highest_Annual_Revenue_Billions DESC
LIMIT 1;