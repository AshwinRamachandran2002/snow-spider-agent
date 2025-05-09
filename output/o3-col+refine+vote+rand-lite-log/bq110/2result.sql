-- Change in homeless-veteran counts (2018 minus 2012) for NY CoCs that have data in BOTH years
SELECT
  `CoC_Number`,
  ANY_VALUE(`CoC_Name`)                AS `CoC_Name`,
  SUM(CASE WHEN `Count_Year` = 2012 THEN `Homeless_Veterans` END) AS `homeless_veterans_2012`,
  SUM(CASE WHEN `Count_Year` = 2018 THEN `Homeless_Veterans` END) AS `homeless_veterans_2018`,
  SUM(CASE WHEN `Count_Year` = 2018 THEN `Homeless_Veterans` END)
  - SUM(CASE WHEN `Count_Year` = 2012 THEN `Homeless_Veterans` END) AS `change_in_homeless_veterans`
FROM
  `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE
  LEFT(`CoC_Number`, 2) = 'NY'        -- New York CoCs
  AND `Count_Year` IN (2012, 2018)    -- retain only the two years of interest
GROUP BY
  `CoC_Number`
HAVING
  COUNT(DISTINCT `Count_Year`) = 2;   -- ensure both years are present