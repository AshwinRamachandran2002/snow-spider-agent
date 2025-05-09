SELECT
  `CoC_Number`,
  MAX(`CoC_Name`) AS CoC_Name,
  MAX(IF(`Count_Year` = 2012, `Homeless_Veterans`, NULL)) AS vets_2012,
  MAX(IF(`Count_Year` = 2018, `Homeless_Veterans`, NULL)) AS vets_2018,
  MAX(IF(`Count_Year` = 2018, `Homeless_Veterans`, NULL)) -
  MAX(IF(`Count_Year` = 2012, `Homeless_Veterans`, NULL)) AS change_2012_to_2018
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE `CoC_Number` LIKE 'NY-%'
  AND `Count_Year` IN (2012, 2018)
GROUP BY `CoC_Number`
HAVING vets_2012 IS NOT NULL
   AND vets_2018 IS NOT NULL
ORDER BY `CoC_Number`;