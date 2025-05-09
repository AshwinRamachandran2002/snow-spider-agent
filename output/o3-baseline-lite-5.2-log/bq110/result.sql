WITH ny_coc AS (
  SELECT
    CoC_Number,
    CoC_Name,
    Count_Year,
    Homeless_Veterans
  FROM
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE
    CoC_Number LIKE 'NY-%'          -- New York CoC regions
    AND Count_Year IN (2012, 2018)  -- years of interest
),
pivot AS (
  SELECT
    CoC_Number,
    CoC_Name,
    MAX(CASE WHEN Count_Year = 2012 THEN Homeless_Veterans END) AS vets_2012,
    MAX(CASE WHEN Count_Year = 2018 THEN Homeless_Veterans END) AS vets_2018
  FROM ny_coc
  GROUP BY CoC_Number, CoC_Name
)
SELECT
  CoC_Number,
  CoC_Name,
  vets_2012,
  vets_2018,
  vets_2018 - vets_2012 AS change_homeless_veterans
FROM pivot
WHERE vets_2012 IS NOT NULL
  AND vets_2018 IS NOT NULL          -- ensure data exists for both years
ORDER BY CoC_Number;