WITH weather_data AS (
  SELECT 
    TO_DATE(g."year" || '-' || LPAD(g."mo",2,'0') || '-' || LPAD(g."da",2,'0'), 'YYYY-MM-DD') AS "Date",
    ROUND(AVG((g."temp" - 32) * 5 / 9), 4) AS "Temperature_Celsius",
    ROUND(
      AVG(CASE WHEN g."prcp" = 99.99 THEN NULL ELSE g."prcp" * 2.54 END),
      4
    ) AS "Precipitation_cm",
    ROUND(
      AVG(CASE WHEN CAST(g."wdsp" AS FLOAT) = 999.9 THEN NULL ELSE CAST(g."wdsp" AS FLOAT) * 0.514444 END),
      4
    ) AS "Wind_Speed_mps"
  FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019" AS g
  INNER JOIN "NOAA_DATA"."NOAA_GSOD"."STATIONS" AS s
    ON g."stn" = s."usaf" AND g."wban" = s."wban"
  WHERE s."state" = 'NY' AND s."name" ILIKE '%ROCHESTER%'
    AND g."year" = '2019'
    AND g."mo" IN ('01', '02', '03')
  GROUP BY "Date"
),
weather_ma AS (
  SELECT
    wd.*,
    ROUND(
      AVG(wd."Temperature_Celsius") OVER (ORDER BY wd."Date" ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),
      4
    ) AS "Temperature_MA8_Celsius",
    ROUND(
      AVG(wd."Precipitation_cm") OVER (ORDER BY wd."Date" ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),
      4
    ) AS "Precipitation_MA8_cm",
    ROUND(
      AVG(wd."Wind_Speed_mps") OVER (ORDER BY wd."Date" ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),
      4
    ) AS "Wind_Speed_MA8_mps"
  FROM weather_data wd
),
weather_diff AS (
  SELECT
    wm.*,
    ROUND(
      wm."Temperature_MA8_Celsius" - LAG(wm."Temperature_MA8_Celsius", 8) OVER (ORDER BY wm."Date"),
      4
    ) AS "Temperature_Difference_Celsius",
    ROUND(
      wm."Precipitation_MA8_cm" - LAG(wm."Precipitation_MA8_cm", 8) OVER (ORDER BY wm."Date"),
      4
    ) AS "Precipitation_Difference_cm",
    ROUND(
      wm."Wind_Speed_MA8_mps" - LAG(wm."Wind_Speed_MA8_mps", 8) OVER (ORDER BY wm."Date"),
      4
    ) AS "Wind_Speed_Difference_mps"
  FROM weather_ma wm
)
SELECT
  "Date",
  "Temperature_Celsius",
  "Precipitation_cm",
  "Wind_Speed_mps",
  "Temperature_MA8_Celsius",
  "Precipitation_MA8_cm",
  "Wind_Speed_MA8_mps",
  "Temperature_Difference_Celsius",
  "Precipitation_Difference_cm",
  "Wind_Speed_Difference_mps"
FROM weather_diff
WHERE "Date" >= '2019-01-09'
ORDER BY "Date" ASC;