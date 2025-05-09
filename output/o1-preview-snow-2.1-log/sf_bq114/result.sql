WITH epa AS (
  SELECT
    ROUND("latitude", 2) AS "lat_rounded",
    ROUND("longitude", 2) AS "lon_rounded",
    MAX("city_name") AS "City",
    AVG("arithmetic_mean") AS "epa_pm25"
  FROM
    "OPENAQ"."EPA_HISTORICAL_AIR_QUALITY"."PM25_FRM_DAILY_SUMMARY"
  WHERE
    "parameter_name" = 'PM2.5 - Local Conditions'
    AND "date_local" >= '2019-01-01' AND "date_local" < '2020-01-01'
  GROUP BY
    "lat_rounded", "lon_rounded"
),
openaq AS (
  SELECT
    ROUND("latitude", 2) AS "lat_rounded",
    ROUND("longitude", 2) AS "lon_rounded",
    MAX("city") AS "City",
    AVG("value") AS "openaq_pm25"
  FROM
    "OPENAQ"."OPENAQ"."GLOBAL_AIR_QUALITY"
  WHERE
    "pollutant" = 'pm25'
    AND TO_TIMESTAMP_NTZ("timestamp" / 1000000) >= '2020-01-01'
    AND TO_TIMESTAMP_NTZ("timestamp" / 1000000) < '2021-01-01'
    AND "country" = 'US'
  GROUP BY
    "lat_rounded", "lon_rounded"
)
SELECT
  COALESCE(epa."City", openaq."City") AS "City",
  ROUND(ABS(openaq."openaq_pm25" - epa."epa_pm25"), 4) AS "Difference_in_PM25_Measurements"
FROM
  epa
INNER JOIN
  openaq
ON
  epa."lat_rounded" = openaq."lat_rounded"
  AND epa."lon_rounded" = openaq."lon_rounded"
WHERE
  openaq."openaq_pm25" IS NOT NULL
  AND epa."epa_pm25" IS NOT NULL
ORDER BY
  "Difference_in_PM25_Measurements" DESC NULLS LAST
LIMIT 3;