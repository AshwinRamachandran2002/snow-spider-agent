/*  Percentage of stations that reported valid (non-NULL and ≠ 9999.9) 
    temperature, maximum, and minimum values on ≥ 90 % of 2022 days          */

WITH all_stations AS (
  -- every station that reported at least one day in 2022
  SELECT DISTINCT stn
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE stn <> '999999'                         -- discard placeholder code
),

valid_day_counts AS (
  -- how many 2022 days had fully-valid temp / max / min for each station
  SELECT
    stn,
    COUNT(DISTINCT DATE(CONCAT(year,'-',mo,'-',da))) AS valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE stn <> '999999'
    AND temp IS NOT NULL AND max IS NOT NULL AND min IS NOT NULL
    AND temp <> 9999.9    AND max <> 9999.9    AND min <> 9999.9
  GROUP BY stn
),

coverage AS (
  -- attach the valid-day counts to every station, defaulting to 0
  SELECT
    a.stn,
    COALESCE(v.valid_days,0) AS valid_days
  FROM all_stations AS a
  LEFT JOIN valid_day_counts AS v USING (stn)
)

SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(valid_days >= 0.90 * 365),   -- stations meeting ≥90 % criterion
      COUNT(*)                             -- all reporting stations in 2022
    ) * 100,                               -- convert to percent
    4                                       -- keep four decimals
  ) AS pct_stations_90pct_or_more
FROM coverage;