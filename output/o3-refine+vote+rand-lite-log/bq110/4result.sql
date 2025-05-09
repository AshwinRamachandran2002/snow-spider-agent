-- Change in the number of homeless veterans (2018 minus 2012)
-- for CoC regions in New York that report data in both years
SELECT
  CoC_Number,
  CoC_Name,
  SUM(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS veterans_2012,
  SUM(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) AS veterans_2018,
  SUM(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END)
  - SUM(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS change_in_homeless_veterans
FROM
  `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE
  CoC_Number LIKE 'NY-%'       -- only New York CoCs
  AND Count_Year IN (2012, 2018)
  AND Homeless_Veterans IS NOT NULL
GROUP BY
  CoC_Number,
  CoC_Name
HAVING
  COUNT(DISTINCT Count_Year) = 2   -- keep only CoCs with data in both years
ORDER BY
  CoC_Number;