SELECT
  CoC_Number,
  CoC_Name,
  MAX(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) - MAX(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS Change_in_Homeless_Veterans
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE CoC_Number LIKE 'NY-%' AND Count_Year IN (2012, 2018)
GROUP BY CoC_Number, CoC_Name
ORDER BY CoC_Number;