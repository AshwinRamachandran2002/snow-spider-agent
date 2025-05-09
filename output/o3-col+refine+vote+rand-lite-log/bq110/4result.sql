-- Change in homeless–veteran counts (2018 − 2012) for NY CoCs with data in BOTH years
SELECT
  `CoC_Number`,
  ANY_VALUE(`CoC_Name`)                         AS `CoC_Name`,
  MAX(IF(`Count_Year` = 2012, `Homeless_Veterans`, NULL)) AS `veterans_2012`,
  MAX(IF(`Count_Year` = 2018, `Homeless_Veterans`, NULL)) AS `veterans_2018`,
  MAX(IF(`Count_Year` = 2018, `Homeless_Veterans`, NULL))
    - MAX(IF(`Count_Year` = 2012, `Homeless_Veterans`, NULL)) AS `change_2012_to_2018`
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE `CoC_Number` LIKE 'NY-%'
  AND `Count_Year` IN (2012, 2018)
GROUP BY `CoC_Number`
HAVING COUNT(DISTINCT `Count_Year`) = 2  -- ensure both years are present
ORDER BY `CoC_Number`;