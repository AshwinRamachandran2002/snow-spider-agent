WITH day_counts AS (
  -- 1.  Count total days and “good” days (no 9999.9 or NULL in temp/max/min)
  SELECT
    stn,
    COUNT(*) AS total_days,
    COUNTIF(
        temp IS NOT NULL AND temp != 9999.9
    AND max  IS NOT NULL AND max  != 9999.9
    AND min  IS NOT NULL AND min  != 9999.9) AS good_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  GROUP BY stn
),
station_validity AS (
  -- 2.  Keep only real stations (USAF ≠ 999999) and compute valid‑day ratio
  SELECT
    dc.stn,
    dc.good_days,
    dc.total_days,
    dc.good_days / dc.total_days AS valid_ratio
  FROM day_counts dc
  JOIN `bigquery-public-data.noaa_gsod.stations` s
    ON dc.stn = s.usaf
  WHERE s.usaf <> '999999'
)
-- 3.  Percentage of stations whose valid‑day ratio ≥ 90 %
SELECT
  ROUND(100 * COUNTIF(valid_ratio >= 0.90) / COUNT(*), 2) AS percent_of_stations_meeting_90pct
FROM station_validity;