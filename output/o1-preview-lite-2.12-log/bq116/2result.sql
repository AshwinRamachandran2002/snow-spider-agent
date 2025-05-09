SELECT s.stprba AS State, 
       SUM(n.value) / 1e9 AS Total_Annual_Revenue_Billions_USD
FROM `bigquery-public-data.sec_quarterly_financials.numbers` AS n
JOIN `bigquery-public-data.sec_quarterly_financials.submission` AS s
  ON n.submission_number = s.submission_number
WHERE n.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
  AND n.number_of_quarters = 4
  AND s.fiscal_year = 2016
  AND s.stprba IS NOT NULL AND s.stprba != ''
GROUP BY State
ORDER BY Total_Annual_Revenue_Billions_USD DESC
LIMIT 1;