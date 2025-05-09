SELECT
  `CoC_Number`,
  `CoC_Name`,
  MAX(CASE WHEN `Count_Year` = 2012 THEN `Homeless_Veterans` END) AS veterans_2012,
  MAX(CASE WHEN `Count_Year` = 2018 THEN `Homeless_Veterans` END) AS veterans_2018,
  MAX(CASE WHEN `Count_Year` = 2018 THEN `Homeless_Veterans` END) -
  MAX(CASE WHEN `Count_Year` = 2012 THEN `Homeless_Veterans` END)   AS change_2012_to_2018
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE `CoC_Number` LIKE 'NY-%'
  AND `Count_Year` IN (2012, 2018)
GROUP BY `CoC_Number`, `CoC_Name`
HAVING COUNT(DISTINCT `Count_Year`) = 2
ORDER BY `CoC_Number`;