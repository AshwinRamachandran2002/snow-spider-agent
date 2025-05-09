WITH stats AS (
  SELECT
    stn,
    COUNT(DISTINCT `date`) AS reported_days,
    COUNTIF(
      temp IS NOT NULL AND temp != 9999.9
      AND `max` IS NOT NULL AND `max` != 9999.9
      AND `min` IS NOT NULL AND `min` != 9999.9
    ) AS valid_temp_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE stn != '999999'
  GROUP BY stn
),
qualified AS (
  SELECT stn
  FROM stats
  WHERE SAFE_DIVIDE(valid_temp_days, reported_days) >= 0.90
),
all_stations AS (
  SELECT usaf AS stn
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE usaf != '999999'
)
SELECT
  ROUND(
    100 * SAFE_DIVIDE(COUNT(DISTINCT q.stn), COUNT(DISTINCT a.stn)),
    4
  ) AS percentage_valid_stations
FROM all_stations AS a
LEFT JOIN qualified AS q
ON a.stn = q.stn;