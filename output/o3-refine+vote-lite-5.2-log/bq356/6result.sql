-- Count NOAA GSOD weather stations that
--   • began service ≤ 2000‑01‑01 AND were still reporting ≥ 2019‑06‑30
--   • have at least one 2019 record with non‑missing temp/max/min
--   • supplied valid temp/max/min data on ≥ 90 % of the 365 days of 2019
WITH valid_2019 AS (
  SELECT
    stn,
    wban,
    COUNT(*) AS valid_days         -- days with all three temperatures present
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE
    temp < 9999       -- filter out GSOD missing sentinels (9999.9 / 9999)
    AND max  < 9999
    AND min  < 9999
  GROUP BY stn, wban
),
eligible_stations AS (
  SELECT
    SAFE_CAST(usaf AS STRING) AS stn,
    SAFE_CAST(wban AS STRING) AS wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE
    -- begin on or before 2000‑01‑01
    SAFE.PARSE_DATE('%Y%m%d', begin) <= DATE '2000-01-01'
    -- end is blank/NULL or on/after 2019‑06‑30
    AND (
          SAFE.PARSE_DATE('%Y%m%d', `end`) IS NULL
          OR SAFE.PARSE_DATE('%Y%m%d', `end`) >= DATE '2019-06-30'
        )
)
SELECT
  COUNT(*) AS stations_with_90pct_coverage_2019
FROM valid_2019 v
JOIN eligible_stations e
  USING (stn, wban)
WHERE v.valid_days >= CEIL(0.90 * 365)   -- ≥ 329 valid‑record days