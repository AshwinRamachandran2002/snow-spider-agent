SELECT
  s.`stprba` AS State,
  ROUND(SUM(n.`value`) / 1e9, 4) AS Highest_Annual_Revenue_Billions
FROM
  `bigquery-public-data.sec_quarterly_financials.numbers` n
JOIN
  `bigquery-public-data.sec_quarterly_financials.submission` s
ON
  n.`submission_number` = s.`submission_number`
WHERE
  n.`number_of_quarters` = 4
  AND n.`units` = 'USD'
  AND n.`value` > 0
  AND n.`measure_tag` IN (
    'Revenues',
    'SalesRevenueNet',
    'RevenueFromContractWithCustomerExcludingAssessedTax'
  )
  AND s.`fiscal_year` = 2016
  AND s.`form` = '10-K'
  AND s.`countryba` = 'US'
GROUP BY
  State
ORDER BY
  Highest_Annual_Revenue_Billions DESC
LIMIT 1