-- Change in the number of homeless veterans (2018 – 2012)
-- for each New York CoC that has data in both years
SELECT
  CoC_Number,
  ANY_VALUE(CoC_Name)                 AS CoC_Name,
  SUM(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS veterans_2012,
  SUM(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) AS veterans_2018,
  SUM(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) -
  SUM(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS change_veterans
FROM
  `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
WHERE
  CoC_Number LIKE 'NY-%'               -- only New York CoC regions
  AND Count_Year IN (2012, 2018)       -- restrict to the two years of interest
GROUP BY
  CoC_Number
HAVING
  veterans_2012 IS NOT NULL            -- ensure both years are present
  AND veterans_2018 IS NOT NULL
ORDER BY
  CoC_Number;