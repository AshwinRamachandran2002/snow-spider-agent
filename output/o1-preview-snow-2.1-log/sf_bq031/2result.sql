SELECT
  t."Date",
  t."Temperature_Celsius",
  t."Precipitation_cm",
  t."Wind_Speed_mps",
  t."Temperature_MA8_Celsius",
  t."Precipitation_MA8_cm",
  t."Wind_Speed_MA8_mps",
  ROUND(
    t."Temperature_MA8_Celsius" - LAG(t."Temperature_MA8_Celsius", 8) OVER (ORDER BY t."Date"), 4
  ) AS "Temperature_Difference_Celsius",
  ROUND(
    t."Precipitation_MA8_cm" - LAG(t."Precipitation_MA8_cm", 8) OVER (ORDER BY t."Date"), 4
  ) AS "Precipitation_Difference_cm",
  ROUND(
    t."Wind_Speed_MA8_mps" - LAG(t."Wind_Speed_MA8_mps", 8) OVER (ORDER BY t."Date"), 4
  ) AS "Wind_Speed_Difference_mps"
FROM (
  SELECT
    TO_DATE(CONCAT(G."year", '-', G."mo", '-', G."da"), 'YYYY-MM-DD') AS "Date",
    ROUND((G."temp" - 32) * 5 / 9, 4) AS "Temperature_Celsius",
    ROUND(G."prcp" * 2.54, 4) AS "Precipitation_cm",
    ROUND(CAST(G."wdsp" AS FLOAT) * 0.514444, 4) AS "Wind_Speed_mps",
    ROUND(
      AVG((G."temp" - 32) * 5 / 9) OVER (
        ORDER BY TO_DATE(CONCAT(G."year", '-', G."mo", '-', G."da"), 'YYYY-MM-DD')
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ), 4
    ) AS "Temperature_MA8_Celsius",
    ROUND(
      AVG(G."prcp" * 2.54) OVER (
        ORDER BY TO_DATE(CONCAT(G."year", '-', G."mo", '-', G."da"), 'YYYY-MM-DD')
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ), 4
    ) AS "Precipitation_MA8_cm",
    ROUND(
      AVG(CAST(G."wdsp" AS FLOAT) * 0.514444) OVER (
        ORDER BY TO_DATE(CONCAT(G."year", '-', G."mo", '-', G."da"), 'YYYY-MM-DD')
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ), 4
    ) AS "Wind_Speed_MA8_mps"
  FROM NOAA_DATA.NOAA_GSOD."GSOD2019" G
  JOIN NOAA_DATA.NOAA_GSOD."STATIONS" S
    ON G."stn" = S."usaf" AND G."wban" = S."wban"
  WHERE S."name" ILIKE '%ROCHESTER%'
    AND S."state" = 'NY'
    AND TO_DATE(CONCAT(G."year", '-', G."mo", '-', G."da"), 'YYYY-MM-DD') >= '2019-01-09'
    AND TO_DATE(CONCAT(G."year", '-', G."mo", '-', G."da"), 'YYYY-MM-DD') <= '2019-03-31'
) t
ORDER BY t."Date" ASC;