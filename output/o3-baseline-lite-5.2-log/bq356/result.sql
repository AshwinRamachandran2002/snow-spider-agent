-- stations with long‑term records that were still reporting in mid‑2019
WITH station_span AS (
  SELECT
    stn,
    wban,
    MIN( DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) ) AS first_obs,
    MAX( DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) ) AS last_obs
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '1929' AND '2024'          -- all GSOD years in the dataset
  GROUP BY stn, wban
  HAVING
    first_obs <= DATE '2000-01-01'        -- record began on or before 01‑Jan‑2000
    AND last_obs  >= DATE '2019-06-30'    -- record extends through at least 30‑Jun‑2019
),

-- 2019 daily temperature validity counts
valid_2019 AS (
  SELECT
    stn,
    wban,
    COUNTIF( temp <  9999               -- valid mean temp
             AND max < 9999             -- valid daily max
             AND min < 9999 )           -- valid daily min
      AS valid_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  GROUP BY stn, wban
  HAVING valid_days_2019 >= 0.9 * 365   -- at least 90 % of possible days (>=329)
)

-- final count
SELECT COUNT(*) AS stations_meeting_criterion
FROM valid_2019
JOIN station_span
USING (stn, wban);