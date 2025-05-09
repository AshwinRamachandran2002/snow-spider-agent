-- Weather stations in Washington (WA) that had
--   • more than 150 rainy days in 2023
--   • but fewer rainy days in 2023 than in 2022
-- A “rainy day” = PRCP > 0  and PRCP != 99.99
-- Only stations with valid precipitation data for BOTH years are considered
WITH rainy_days AS (
  -- 2023
  SELECT
    stn        AS usaf,
    wban,
    2023       AS yr,
    COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_cnt
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  WHERE prcp IS NOT NULL
  GROUP BY usaf, wban

  UNION ALL

  -- 2022
  SELECT
    stn        AS usaf,
    wban,
    2022       AS yr,
    COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_cnt
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE prcp IS NOT NULL
  GROUP BY usaf, wban
),
pivoted AS (
  SELECT
    usaf,
    wban,
    MAX(CASE WHEN yr = 2023 THEN rainy_cnt END) AS rainy_2023,
    MAX(CASE WHEN yr = 2022 THEN rainy_cnt END) AS rainy_2022
  FROM rainy_days
  GROUP BY usaf, wban
),
wa_stations AS (
  SELECT
    p.usaf,
    p.wban,
    s.name,
    p.rainy_2023,
    p.rainy_2022
  FROM pivoted p
  JOIN `bigquery-public-data.noaa_gsod.stations` s
    ON s.usaf = p.usaf AND s.wban = p.wban
  WHERE s.country = 'US'            -- United States
    AND s.state   = 'WA'            -- Washington
    AND p.rainy_2023 > 150          -- >150 rainy days in 2023
    AND p.rainy_2022 IS NOT NULL    -- need 2022 data to compare
    AND p.rainy_2023 < p.rainy_2022 -- fewer in 2023 than 2022
)
SELECT
  usaf,
  wban,
  TRIM(name)                       AS station_name,
  rainy_2023,
  rainy_2022
FROM wa_stations
ORDER BY rainy_2023 DESC, usaf, wban;