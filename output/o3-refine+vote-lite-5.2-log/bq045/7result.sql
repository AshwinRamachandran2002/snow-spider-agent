-- Weather stations in Washington (state = 'WA') that
-- had >150 rainy days in 2023 and fewer rainy days in 2022.
-- “Rainy day” = prcp > 0 and prcp ≠ 99.99 (valid precip).

WITH rainy_per_year AS (
  SELECT
    stn,
    wban,
    2020 + CAST(_TABLE_SUFFIX AS INT64) AS year,          -- 2022 / 2023
    COUNT(*) AS rainy_days
  FROM
    `bigquery-public-data.noaa_gsod.gsod202*`
  WHERE
    _TABLE_SUFFIX IN ('2','3')                            -- 2022 and 2023 tables
    AND prcp IS NOT NULL
    AND prcp != 99.99                                     -- valid precip only
    AND prcp > 0                                          -- rainy day
  GROUP BY
    stn, wban, year
),

pivoted AS (
  SELECT
    stn,
    wban,
    MAX(CASE WHEN year = 2022 THEN rainy_days END) AS rainy_2022,
    MAX(CASE WHEN year = 2023 THEN rainy_days END) AS rainy_2023
  FROM rainy_per_year
  GROUP BY stn, wban
),

wa_stations AS (
  SELECT
    TRIM(name) AS station_name,
    usaf AS stn,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'WA'
)

SELECT
  ws.station_name,
  ws.stn      AS usaf,
  ws.wban,
  p.rainy_2023,
  p.rainy_2022
FROM pivoted p
JOIN wa_stations ws
  ON p.stn = ws.stn
 AND p.wban = ws.wban
WHERE
      p.rainy_2023 > 150          -- >150 rainy days in 2023
  AND p.rainy_2022 IS NOT NULL    -- must have data for 2022
  AND p.rainy_2023 > p.rainy_2022 -- fewer rainy days in 2022
ORDER BY
  p.rainy_2023 DESC,
  ws.station_name;