-- Change in the number of homeless veterans between 2012 and 2018
-- for every New York Continuum of Care (CoC) that has data in BOTH years
SELECT
  `CoC_Number`,
  ANY_VALUE(`CoC_Name`) AS `CoC_Name`,
  -- totals for each year
  SUM(CASE WHEN `Count_Year` = 2012 THEN `Homeless_Veterans` END) AS vets_2012,
  SUM(CASE WHEN `Count_Year` = 2018 THEN `Homeless_Veterans` END) AS vets_2018,
  -- difference: 2018 minus 2012
  SUM(CASE WHEN `Count_Year` = 2018 THEN `Homeless_Veterans` END)
  - SUM(CASE WHEN `Count_Year` = 2012 THEN `Homeless_Veterans` END) AS change_2012_2018
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE `CoC_Number` LIKE 'NY-%'               -- New York CoCs only
  AND `Count_Year` IN (2012, 2018)           -- keep just the two target years
GROUP BY `CoC_Number`
HAVING
  -- ensure data present in both years
  SUM(CASE WHEN `Count_Year` = 2012 THEN `Homeless_Veterans` END) IS NOT NULL
  AND
  SUM(CASE WHEN `Count_Year` = 2018 THEN `Homeless_Veterans` END) IS NOT NULL
ORDER BY change_2012_2018 DESC;