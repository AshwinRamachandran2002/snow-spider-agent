-- Stations in Washington (WA) that had >150 “rainy days” in 2023
-- but fewer rainy days than in 2022.
-- A “rainy day” = prcp > 0 AND prcp <> 99.99 (99.99 = missing/trace).

WITH rainy_2023 AS (
  SELECT
    s.usaf,
    s.wban,
    COUNTIF(g.prcp > 0 AND g.prcp <> 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE s.state = 'WA'
  GROUP BY s.usaf, s.wban
),
rainy_2022 AS (
  SELECT
    s.usaf,
    s.wban,
    COUNTIF(g.prcp > 0 AND g.prcp <> 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE s.state = 'WA'
  GROUP BY s.usaf, s.wban
),
combined AS (
  SELECT
    r23.usaf,
    r23.wban,
    r23.rainy_days_2023,
    r22.rainy_days_2022
  FROM rainy_2023 AS r23
  JOIN rainy_2022 AS r22
    USING (usaf, wban)
)
SELECT
  TRIM(st.name)           AS station_name,
  st.usaf                 AS usaf_id,
  st.wban                 AS wban_id,
  c.rainy_days_2023,
  c.rainy_days_2022
FROM combined AS c
JOIN `bigquery-public-data.noaa_gsod.stations` AS st
  USING (usaf, wban)
WHERE c.rainy_days_2023 > 150          -- >150 rainy days in 2023
  AND c.rainy_days_2023 < c.rainy_days_2022   -- fewer than in 2022
ORDER BY c.rainy_days_2023 DESC;