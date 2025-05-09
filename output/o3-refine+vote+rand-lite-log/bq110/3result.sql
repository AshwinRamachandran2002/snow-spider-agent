WITH ny_veterans AS (
  SELECT
    CoC_Number,
    CoC_Name,
    Count_Year,
    Homeless_Veterans
  FROM
    `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
  WHERE
        CoC_Number LIKE 'NY-%'        -- New York CoCs
    AND Count_Year IN (2012, 2018)    -- years of interest
    AND Homeless_Veterans IS NOT NULL -- keep rows with data
)

SELECT
  v12.CoC_Number,
  v12.CoC_Name,
  v12.Homeless_Veterans AS veterans_2012,
  v18.Homeless_Veterans AS veterans_2018,
  v18.Homeless_Veterans - v12.Homeless_Veterans AS change_in_homeless_veterans
FROM
  ny_veterans AS v12
JOIN
  ny_veterans AS v18
USING (CoC_Number, CoC_Name)
WHERE
      v12.Count_Year = 2012
  AND v18.Count_Year = 2018
ORDER BY
  change_in_homeless_veterans DESC;