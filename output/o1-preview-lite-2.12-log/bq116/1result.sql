SELECT s.stprba AS State, ROUND(SUM(n.value)/1000000000, 4) AS Highest_Annual_Revenue_Billions
FROM `bigquery-public-data.sec_quarterly_financials.numbers` n
JOIN `bigquery-public-data.sec_quarterly_financials.submission` s
  ON n.submission_number = s.submission_number
WHERE n.number_of_quarters = 4
  AND n.period_end_date BETWEEN 20160101 AND 20161231
  AND n.measure_tag = 'Revenues'
  AND n.value > 0
  AND s.countryba = 'US'
  AND s.stprba IS NOT NULL
  AND s.stprba != ''
GROUP BY s.stprba
ORDER BY Highest_Annual_Revenue_Billions DESC
LIMIT 1;