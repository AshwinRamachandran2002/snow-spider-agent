SELECT
  CoC_Number,
  ANY_VALUE(CoC_Name) AS CoC_Name,
  SUM(IF(Count_Year = 2012, Homeless_Veterans, 0)) AS vets_2012,
  SUM(IF(Count_Year = 2018, Homeless_Veterans, 0)) AS vets_2018,
  SUM(IF(Count_Year = 2018, Homeless_Veterans, 0)) -
  SUM(IF(Count_Year = 2012, Homeless_Veterans, 0)) AS change_2012_to_2018
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE CoC_Number LIKE 'NY-%'
  AND Count_Year IN (2012, 2018)
GROUP BY CoC_Number
HAVING COUNT(DISTINCT Count_Year) = 2      -- keep only CoCs with data in both years
ORDER BY change_2012_to_2018 DESC;