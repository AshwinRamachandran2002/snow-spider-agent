WITH ny_coc AS (
  SELECT
    CoC_Number,
    CoC_Name,
    Count_Year,
    Homeless_Veterans
  FROM
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE
    Count_Year IN (2012, 2018)                     -- years of interest
    AND REGEXP_CONTAINS(CoC_Number, r'^NY-')       -- New York CoCs
    AND Homeless_Veterans IS NOT NULL              -- ensure data present
),
pivot AS (
  SELECT
    CoC_Number,
    ANY_VALUE(CoC_Name) AS CoC_Name,
    MAX(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS veterans_2012,
    MAX(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) AS veterans_2018
  FROM ny_coc
  GROUP BY CoC_Number
  HAVING COUNT(DISTINCT Count_Year) = 2            -- keep CoCs with both years
)
SELECT
  CoC_Number,
  CoC_Name,
  veterans_2012,
  veterans_2018,
  (veterans_2018 - veterans_2012) AS change_in_homeless_veterans
FROM pivot
ORDER BY CoC_Number;