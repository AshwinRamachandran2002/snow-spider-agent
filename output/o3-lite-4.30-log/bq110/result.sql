SELECT
  CoC_Number AS coc_number,
  MAX(IF(Count_Year = 2018, Homeless_Veterans, NULL))
    - MAX(IF(Count_Year = 2012, Homeless_Veterans, NULL)) AS change_in_homeless_veterans_2012_2018
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE CoC_Number LIKE 'NY-%'
  AND Count_Year IN (2012, 2018)
GROUP BY CoC_Number
HAVING COUNT(DISTINCT Count_Year) = 2
ORDER BY CoC_Number;