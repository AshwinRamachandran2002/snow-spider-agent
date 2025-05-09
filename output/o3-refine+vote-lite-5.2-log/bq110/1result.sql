SELECT
  CoC_Number,
  MAX(CoC_Name)                         AS CoC_Name,
  MAX(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS homeless_veterans_2012,
  MAX(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) AS homeless_veterans_2018,
  MAX(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) -
  MAX(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS change_in_homeless_veterans
FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE
  CoC_Number LIKE 'NY-%'          -- New York CoC regions
  AND Count_Year IN (2012, 2018)  -- only the two years of interest
GROUP BY
  CoC_Number
HAVING
  homeless_veterans_2012 IS NOT NULL
  AND homeless_veterans_2018 IS NOT NULL   -- keep CoCs with data in both years
ORDER BY
  change_in_homeless_veterans DESC,
  CoC_Number;