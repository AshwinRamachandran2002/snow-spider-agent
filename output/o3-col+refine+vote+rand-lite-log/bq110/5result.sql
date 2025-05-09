SELECT
  c2012.`CoC_Number`,
  c2012.`CoC_Name`,
  c2012.`Homeless_Veterans` AS `Veterans_2012`,
  c2018.`Homeless_Veterans` AS `Veterans_2018`,
  c2018.`Homeless_Veterans` - c2012.`Homeless_Veterans` AS `Change_2012_to_2018`
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc` AS c2012
JOIN `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc` AS c2018
  ON c2012.`CoC_Number` = c2018.`CoC_Number`
WHERE c2012.`CoC_Number` LIKE 'NY-%'    -- restrict to New York CoCs
  AND c2012.`Count_Year` = 2012         -- 2012 veteran counts
  AND c2018.`Count_Year` = 2018         -- 2018 veteran counts
ORDER BY c2012.`CoC_Number`;