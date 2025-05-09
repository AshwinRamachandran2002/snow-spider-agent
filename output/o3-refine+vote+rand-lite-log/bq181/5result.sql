-- Percentage of stations that reported valid temperature data
-- (temp, max, min all present and not 9999.9) on ≥ 90 % of 2022 days

WITH per_row AS (
  SELECT
    stn,                                             -- USAF station id
    DATE(CAST(year AS INT64),
         CAST(mo   AS INT64),
         CAST(da   AS INT64))           AS day_date,
    temp, max, min
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE stn <> '999999'                                -- ignore invalid id
),
per_day AS (                                            -- one record per station‑day
  SELECT
    stn,
    day_date,
    MAX( CASE
            WHEN temp IS NOT NULL             AND max IS NOT NULL             AND min IS NOT NULL
             AND temp <> 9999.9              AND max <> 9999.9              AND min <> 9999.9
            THEN 1 ELSE 0
         END )                            AS valid_flag
  FROM per_row
  GROUP BY stn, day_date
),
station_stats AS (                                      -- day counts per station
  SELECT
    stn,
    COUNT(*)                    AS days_reported,       -- days having any record
    SUM(valid_flag)             AS valid_days
  FROM per_day
  GROUP BY stn
),
qualified AS (                                          -- ≥ 90 % of 365 days
  SELECT stn
  FROM station_stats
  WHERE valid_days >= 0.9 * 365
)

SELECT
  ROUND(
    100 * SAFE_DIVIDE( (SELECT COUNT(*)       FROM qualified),
                       (SELECT COUNT(DISTINCT stn) FROM per_day)
    )
  ,2) AS pct_stations_with_90pct_valid_2022;