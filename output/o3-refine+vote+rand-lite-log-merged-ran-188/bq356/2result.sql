/*  Stations that
    1) began service on or before 2000‑01‑01 and were still reporting
       on or after 2019‑06‑30,
    2) supplied non‑missing temp / max / min values during 2019,
    3) did so on ≥ 90 % of the 365 days of 2019 (≥ 329 days).           */

WITH long_record_stations AS (
  SELECT
    usaf AS stn,
    wban
  FROM
    `bigquery-public-data.noaa_gsod.stations`
  WHERE
    --  valid begin / end dates
    SAFE.PARSE_DATE('%Y%m%d', `begin`) IS NOT NULL
    AND SAFE.PARSE_DATE('%Y%m%d', `end`)   IS NOT NULL
    --  period of record spans the required window
    AND SAFE.PARSE_DATE('%Y%m%d', `begin`) <= DATE '2000-01-01'
    AND SAFE.PARSE_DATE('%Y%m%d', `end`)   >= DATE '2019-06-30'
),

valid_2019_counts AS (
  SELECT
    stn,
    wban,
    COUNT(DISTINCT DATE(CAST(year AS INT64),
                        CAST(mo   AS INT64),
                        CAST(da   AS INT64))) AS valid_days
  FROM
    `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE
    temp < 9999.0       -- non‑missing daily mean temp
    AND max  < 9999.0   -- non‑missing daily max
    AND min  < 9999.0   -- non‑missing daily min
  GROUP BY
    stn, wban
),

eligible_stations AS (
  SELECT
    v.stn,
    v.wban
  FROM
    valid_2019_counts v
  JOIN
    long_record_stations s
  USING (stn, wban)
  WHERE
    v.valid_days >= 0.90 * 365   -- ≥ 90 % of 2019
)

SELECT
  COUNT(*) AS stations_meeting_criteria
FROM
  eligible_stations;