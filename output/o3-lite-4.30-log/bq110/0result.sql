WITH ny_vets AS (
  SELECT
    CoC_Number,
    Count_Year,
    SUM(Homeless_Veterans) AS vets
  FROM `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE STARTS_WITH(CoC_Number,'NY-')
    AND Count_Year IN (2012, 2018)
  GROUP BY CoC_Number, Count_Year
),
pivot AS (
  SELECT
    CoC_Number,
    MAX(CASE WHEN Count_Year = 2012 THEN vets END) AS vets_2012,
    MAX(CASE WHEN Count_Year = 2018 THEN vets END) AS vets_2018
  FROM ny_vets
  GROUP BY CoC_Number
)
SELECT
  CoC_Number AS coc_number,
  vets_2018 - vets_2012 AS change_in_homeless_veterans_2012_2018
FROM pivot
WHERE vets_2012 IS NOT NULL
  AND vets_2018 IS NOT NULL
ORDER BY CoC_Number;