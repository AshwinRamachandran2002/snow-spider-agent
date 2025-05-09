SELECT
  CoC_Number,
  CoC_Name,
  veterans_2012,
  veterans_2018,
  veterans_2018 - veterans_2012 AS change_in_homeless_veterans
FROM (
  SELECT
    CoC_Number,
    MAX(CoC_Name) AS CoC_Name,
    SUM(IF(Count_Year = 2012, IFNULL(Homeless_Veterans, 0), 0)) AS veterans_2012,
    SUM(IF(Count_Year = 2018, IFNULL(Homeless_Veterans, 0), 0)) AS veterans_2018
  FROM
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE
    CoC_Number LIKE 'NY-%'            -- New York CoCs
    AND Count_Year IN (2012, 2018)    -- only keep 2012 and 2018
  GROUP BY
    CoC_Number
) AS t
WHERE
  veterans_2012 IS NOT NULL
  AND veterans_2018 IS NOT NULL        -- ensure both years present
ORDER BY
  CoC_Number;