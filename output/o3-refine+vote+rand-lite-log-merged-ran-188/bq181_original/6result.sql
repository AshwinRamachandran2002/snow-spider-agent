-- Percentage of NOAA‑GSOD weather stations that reported
-- valid (non‑missing, non‑9999.9) daily temperature, max
-- and min values on at least 90 % of the 365 days in 2022
SELECT
  ROUND(100.0 * qualified_cnt / total_cnt, 2) AS pct_stations_with_90pct_valid_data
FROM (
  /* stations that meet the ≥90 % valid‑days requirement */
  SELECT
    COUNT(DISTINCT stn) AS qualified_cnt
  FROM (
    SELECT
      stn,
      COUNT(*) AS valid_days
    FROM
      `bigquery-public-data.noaa_gsod.gsod2022`
    WHERE
      stn           != '999999'       -- valid USAF identifier
      AND temp IS NOT NULL AND temp != 9999.9
      AND max  IS NOT NULL AND max  != 9999.9
      AND min  IS NOT NULL AND min  != 9999.9
    GROUP BY
      stn
    HAVING
      COUNT(*) >= 0.9 * 365           -- ≥90 % of days in 2022
  )
) AS qualified
CROSS JOIN (
  /* all available GSOD stations with valid USAF codes */
  SELECT
    COUNT(DISTINCT usaf) AS total_cnt
  FROM
    `bigquery-public-data.noaa_gsod.stations`
  WHERE
    usaf != '999999'
) AS total;