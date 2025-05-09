-- Change in homeless-veteran counts (2018 minus 2012) for New York CoCs
SELECT
  CoC_Number,
  MAX(CoC_Name) AS CoC_Name,
  SUM(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS veterans_2012,
  SUM(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) AS veterans_2018,
  SUM(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END)
    - SUM(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS change_2018_minus_2012
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE CoC_Number LIKE 'NY-%'
  AND Count_Year IN (2012, 2018)
GROUP BY CoC_Number
HAVING
  COUNTIF(Count_Year = 2012) > 0
  AND COUNTIF(Count_Year = 2018) > 0
ORDER BY change_2018_minus_2012 DESC;