-- Change in the number of homeless veterans between 2012 and 2018
-- for every New York CoC that reports data in BOTH years
WITH ny_coc AS (
  SELECT
    CoC_Number,
    CoC_Name,
    Count_Year,
    SUM(Homeless_Veterans) AS veterans
  FROM
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE
    CoC_Number LIKE 'NY-%'                -- New York CoCs
    AND Count_Year IN (2012, 2018)        -- keep only the two years of interest
  GROUP BY
    CoC_Number, CoC_Name, Count_Year
),
pivot AS (
  SELECT
    CoC_Number,
    CoC_Name,
    MAX(CASE WHEN Count_Year = 2012 THEN veterans END) AS vets_2012,
    MAX(CASE WHEN Count_Year = 2018 THEN veterans END) AS vets_2018
  FROM ny_coc
  GROUP BY
    CoC_Number, CoC_Name
)
SELECT
  CoC_Number,
  CoC_Name,
  vets_2012,
  vets_2018,
  vets_2018 - vets_2012 AS change_in_homeless_veterans
FROM
  pivot
WHERE
  vets_2012 IS NOT NULL
  AND vets_2018 IS NOT NULL          -- ensure data exists for both years
ORDER BY
  CoC_Number;